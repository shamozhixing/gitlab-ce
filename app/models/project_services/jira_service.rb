# == Schema Information
#
# Table name: services
#
#  id                    :integer          not null, primary key
#  type                  :string(255)
#  title                 :string(255)
#  project_id            :integer
#  created_at            :datetime
#  updated_at            :datetime
#  active                :boolean          default(FALSE), not null
#  properties            :text
#  template              :boolean          default(FALSE)
#  push_events           :boolean          default(TRUE)
#  issues_events         :boolean          default(TRUE)
#  merge_requests_events :boolean          default(TRUE)
#  tag_push_events       :boolean          default(TRUE)
#  note_events           :boolean          default(TRUE), not null
#  build_events          :boolean          default(FALSE), not null
#

class JiraService < IssueTrackerService
  include HTTParty
  include Gitlab::Application.routes.url_helpers

  DEFAULT_API_VERSION = 2

  prop_accessor :username, :password, :api_url, :jira_issue_transition_id,
                :title, :description, :project_url, :issues_url, :new_issue_url

  before_validation :set_api_url, :set_jira_issue_transition_id

  before_update :reset_password

  def reset_password
    # don't reset the password if a new one is provided
    if api_url_changed? && !password_touched?
      self.password = nil
    end
  end

  def help
    # If you change something here, it also needs to be changed in the
    # documentation as well: doc/project_services/jira.md
    '
For more details on how to set up the JIRA service, follow the
[JIRA documentation](http://doc.gitlab.com/ce/project_services/jira.html).

---

- **Description:** A name for the issue tracker (to differentiate between
  instances, for example). The default is **JIRA issue tracker**.
- **Project URL:** The URL to the JIRA project which is being linked to this
  GitLab project. It is of the form:
  `https://<jira_host_url>/issues/?jql=project=<jira_project>`.
- **Issues URL:**  The URL to the JIRA project issues overview for the project
  that is linked to this GitLab project. It is of the form:
  `https://<jira_host_url>/browse/:id`.
  Leave `:id` as-is, it gets replaced by GitLab at runtime.
- **New issue URL:** The URL to create a new issue in JIRA for the project
  linked to this GitLab project. It is of the form:
  `https://<jira_host_url>/secure/CreateIssue.jspa`.
- **API URL:** The base URL of the JIRA API. It may be omitted, in which case
  GitLab will automatically use API version `2` based on the `project url`.
  It is of the form: `https://<jira_host_url>/rest/api/2`.
- **Username:** The username of the JIRA user.
- **Password:** The password of the JIRA user.
- **JIRA issue transition:** This setting is very important to set up correctly.
  It is the ID of a transition that moves issues to a closed state. You can
  find this number under the JIRA workflow administration
  (**Administration > Issues > Workflows**) by selecting **View** under
  **Operations** of the desired workflow of your project. The ID of each state
  can be found inside the parenthesis of each transition name under the
  **Transitions (id)** column
  ([see screenshot](http://doc.gitlab.com/ce/project_services/img/jira_issues_workflow.png)).
  By default, this ID is set to `2`.'
  end

  def title
    if self.properties && self.properties['title'].present?
      self.properties['title']
    else
      'JIRA'
    end
  end

  def description
    if self.properties && self.properties['description'].present?
      self.properties['description']
    else
      'JIRA issue tracker'
    end
  end

  def to_param
    'jira'
  end

  def fields
    super.push(
      { type: 'text', name: 'api_url', placeholder: 'https://jira.example.com/rest/api/2' },
      { type: 'text', name: 'username', placeholder: '' },
      { type: 'password', name: 'password', placeholder: '' },
      { type: 'text', name: 'jira_issue_transition_id', placeholder: '2' }
    )
  end

  def execute(push, issue = nil)
    if issue.nil?
      # No specific issue, that means
      # we just want to test settings
      test_settings
    else
      close_issue(push, issue)
    end
  end

  def create_cross_reference_note(mentioned, noteable, author)
    issue_name = mentioned.id
    project = self.project
    noteable_name = noteable.class.name.underscore.downcase
    noteable_id = if noteable.is_a?(Commit)
                    noteable.id
                  else
                    noteable.iid
                  end

    entity_url = build_entity_url(noteable_name.to_sym, noteable_id)

    data = {
      user: {
        name: author.name,
        url: resource_url(user_path(author)),
      },
      project: {
        name: project.path_with_namespace,
        url: resource_url(namespace_project_path(project.namespace, project))
      },
      entity: {
        name: noteable_name.humanize.downcase,
        url: entity_url
      }
    }

    add_comment(data, issue_name)
  end

  def test_settings
    return unless api_url.present?
    result = JiraService.get(
      jira_api_test_url,
      headers: {
        'Content-Type' => 'application/json',
        'Authorization' => "Basic #{auth}"
      }
    )

    case result.code
    when 201, 200
      Rails.logger.info("#{self.class.name} SUCCESS #{result.code}: Successfully connected to #{api_url}.")
      true
    else
      Rails.logger.info("#{self.class.name} ERROR #{result.code}: #{result.parsed_response}")
      false
    end
  rescue Errno::ECONNREFUSED => e
    Rails.logger.info "#{self.class.name} ERROR: #{e.message}. API URL: #{api_url}."
    false
  end

  private

  def build_api_url_from_project_url
    server = URI(project_url)
    default_ports = [["http",80],["https",443]].include?([server.scheme,server.port])
    server_url = "#{server.scheme}://#{server.host}"
    server_url.concat(":#{server.port}") unless default_ports
    "#{server_url}/rest/api/#{DEFAULT_API_VERSION}"
  rescue
    "" # looks like project URL was not valid
  end

  def set_api_url
    self.api_url = build_api_url_from_project_url if self.api_url.blank?
  end

  def set_jira_issue_transition_id
    self.jira_issue_transition_id ||= "2"
  end

  def close_issue(entity, issue)
    commit_id = if entity.is_a?(Commit)
                  entity.id
                elsif entity.is_a?(MergeRequest)
                  entity.last_commit.id
                end
    commit_url = build_entity_url(:commit, commit_id)

    # Depending on the JIRA project's workflow, a comment during transition
    # may or may not be allowed. Split the operation in to two calls so the
    # comment always works.
    transition_issue(issue)
    add_issue_solved_comment(issue, commit_id, commit_url)
  end

  def transition_issue(issue)
    message = {
      transition: {
        id: jira_issue_transition_id
      }
    }
    send_message(close_issue_url(issue.iid), message.to_json)
  end

  def add_issue_solved_comment(issue, commit_id, commit_url)
    comment = {
      body: "Issue solved with [#{commit_id}|#{commit_url}]."
    }

    send_message(comment_url(issue.iid), comment.to_json)
  end

  def add_comment(data, issue_name)
    url = comment_url(issue_name)
    user_name = data[:user][:name]
    user_url = data[:user][:url]
    entity_name = data[:entity][:name]
    entity_url = data[:entity][:url]
    project_name = data[:project][:name]

    message = {
      body: "[#{user_name}|#{user_url}] mentioned this issue in [a #{entity_name} of #{project_name}|#{entity_url}]."
    }

    unless existing_comment?(issue_name, message[:body])
      send_message(url, message.to_json)
    end
  end


  def auth
    require 'base64'
    Base64.urlsafe_encode64("#{self.username}:#{self.password}")
  end

  def send_message(url, message)
    return unless api_url.present?
    result = JiraService.post(
      url,
      body: message,
      headers: {
        'Content-Type' => 'application/json',
        'Authorization' => "Basic #{auth}"
      }
    )

    message = case result.code
              when 201, 200, 204
                "#{self.class.name} SUCCESS #{result.code}: Successfully posted to #{url}."
              when 401
                "#{self.class.name} ERROR 401: Unauthorized. Check the #{self.username} credentials and JIRA access permissions and try again."
              else
                "#{self.class.name} ERROR #{result.code}: #{result.parsed_response}"
              end

    Rails.logger.info(message)
    message
  rescue URI::InvalidURIError, Errno::ECONNREFUSED => e
    Rails.logger.info "#{self.class.name} ERROR: #{e.message}. Hostname: #{url}."
  end

  def existing_comment?(issue_name, new_comment)
    return unless api_url.present?
    result = JiraService.get(
      comment_url(issue_name),
      headers: {
        'Content-Type' => 'application/json',
        'Authorization' => "Basic #{auth}"
      }
    )

    case result.code
    when 201, 200
      existing_comments = JSON.parse(result.body)['comments']

      if existing_comments.present?
        return existing_comments.map { |comment| comment['body'].include?(new_comment) }.any?
      end
    end

    false
  rescue JSON::ParserError
    false
  end

  def resource_url(resource)
    "#{Settings.gitlab['url'].chomp("/")}#{resource}"
  end

  def build_entity_url(entity_name, entity_id)
    resource_url(
      polymorphic_url(
        [
          self.project.namespace.becomes(Namespace),
          self.project,
          entity_name
        ],
        id: entity_id,
        routing_type: :path
      )
    )
  end

  def close_issue_url(issue_name)
    "#{self.api_url}/issue/#{issue_name}/transitions"
  end

  def comment_url(issue_name)
    "#{self.api_url}/issue/#{issue_name}/comment"
  end

  def jira_api_test_url
    "#{self.api_url}/myself"
  end
end
