class Ability
  class << self
    # rubocop: disable Metrics/CyclomaticComplexity
    def allowed(user, subject)
      if ability_class(subject)
        ability_class(subject).abilities(user, subject)
      else
        return anonymous_abilities(user, subject) if user.nil?
        return [] unless user.is_a?(User)
        return [] if user.blocked?

        case subject
        when CommitStatus then commit_status_abilities(user, subject)
        when Issue then issue_abilities(user, subject)
        when Note then note_abilities(user, subject)
        when ProjectSnippet then project_snippet_abilities(user, subject)
        when PersonalSnippet then personal_snippet_abilities(user, subject)
        when MergeRequest then merge_request_abilities(user, subject)
        when Group then group_abilities(user, subject)
        when Namespace then namespace_abilities(user, subject)
        when GroupMember then group_member_abilities(user, subject)
        when ProjectMember then project_member_abilities(user, subject)
        when ExternalIssue, Deployment, Environment then project_abilities(user, subject.project)
        when Ci::Runner then runner_abilities(user, subject)
        else []
        end.concat(global_abilities(user))
      end
    end

    def ability_class(subject)
      "#{subject.class}Abilities".constantize
    rescue NameError
      nil
    end

    # Given a list of users and a project this method returns the users that can
    # read the given project.
    def users_that_can_read_project(users, project)
      if project.public?
        users
      else
        users.select do |user|
          if user.admin?
            true
          elsif project.internal? && !user.external?
            true
          elsif project.owner == user
            true
          elsif project.team.members.include?(user)
            true
          else
            false
          end
        end
      end
    end

    # List of possible abilities for anonymous user
    def anonymous_abilities(user, subject)
      if subject.is_a?(PersonalSnippet)
        anonymous_personal_snippet_abilities(subject)
      elsif subject.is_a?(ProjectSnippet)
        anonymous_project_snippet_abilities(subject)
      elsif subject.is_a?(CommitStatus)
        anonymous_commit_status_abilities(subject)
      elsif subject.is_a?(Project) || subject.respond_to?(:project)
        ProjectAbilities.abilities(user, subject)
      elsif subject.is_a?(Group) || subject.respond_to?(:group)
        anonymous_group_abilities(subject)
      else
        []
      end
    end

    def anonymous_commit_status_abilities(subject)
      rules = ProjectAbilities.abilities(nil, subject.project)
      # If subject is Ci::Build which inherits from CommitStatus filter the abilities
      rules = filter_build_abilities(rules) if subject.is_a?(Ci::Build)
      rules
    end

    def anonymous_group_abilities(subject)
      rules = []

      group = if subject.is_a?(Group)
                subject
              else
                subject.group
              end

      rules << :read_group if group.public?

      rules
    end

    def anonymous_personal_snippet_abilities(snippet)
      if snippet.public?
        [:read_personal_snippet]
      else
        []
      end
    end

    def anonymous_project_snippet_abilities(snippet)
      if snippet.public?
        [:read_project_snippet]
      else
        []
      end
    end

    def global_abilities(user)
      rules = []
      rules << :create_group if user.can_create_group
      rules << :read_users_list
      rules
    end

    def project_abilities(user, project)
      ProjectAbilities.abilities(user, project)
    end

    def project_disabled_features_rules(project)
      rules = []

      unless project.issues_enabled
        rules += named_abilities('issue')
      end

      unless project.merge_requests_enabled
        rules += named_abilities('merge_request')
      end

      unless project.issues_enabled or project.merge_requests_enabled
        rules += named_abilities('label')
        rules += named_abilities('milestone')
      end

      unless project.snippets_enabled
        rules += named_abilities('project_snippet')
      end

      unless project.wiki_enabled
        rules += named_abilities('wiki')
      end

      unless project.builds_enabled
        rules += named_abilities('build')
        rules += named_abilities('pipeline')
        rules += named_abilities('environment')
        rules += named_abilities('deployment')
      end

      unless project.container_registry_enabled
        rules += named_abilities('container_image')
      end

      rules
    end

    def group_abilities(user, group)
      rules = []
      rules << :read_group if can_read_group?(user, group)

      owner = user.admin? || group.has_owner?(user)
      master = owner || group.has_master?(user)

      # Only group masters and group owners can create new projects
      if master
        rules += [
          :create_projects,
          :admin_milestones
        ]
      end

      # Only group owner and administrators can admin group
      if owner
        rules += [
          :admin_group,
          :admin_namespace,
          :admin_group_member,
          :change_visibility_level
        ]
      end

      if group.public? || (group.internal? && !user.external?)
        rules << :request_access unless group.users.include?(user)
      end

      rules.flatten
    end

    def can_read_group?(user, group)
      return true if user.admin?
      return true if group.public?
      return true if group.internal? && !user.external?
      return true if group.users.include?(user)

      GroupProjectsFinder.new(group).execute(user).any?
    end

    def namespace_abilities(user, namespace)
      rules = []

      # Only namespace owner and administrators can admin it
      if namespace.owner == user || user.admin?
        rules += [
          :create_projects,
          :admin_namespace
        ]
      end

      rules.flatten
    end

    [:issue, :merge_request].each do |name|
      define_method "#{name}_abilities" do |user, subject|
        rules = []

        if subject.author == user || (subject.respond_to?(:assignee) && subject.assignee == user)
          rules += [
            :"read_#{name}",
            :"update_#{name}",
          ]
        end

        rules += project_abilities(user, subject.project)
        rules = filter_confidential_issues_abilities(user, subject, rules) if subject.is_a?(Issue)
        rules
      end
    end

    def note_abilities(user, note)
      rules = []

      if note.author == user
        rules += [
          :read_note,
          :update_note,
          :admin_note
        ]
      end

      if note.respond_to?(:project) && note.project
        rules += project_abilities(user, note.project)
      end

      rules
    end

    def personal_snippet_abilities(user, snippet)
      rules = []

      if snippet.author == user
        rules += [
          :read_personal_snippet,
          :update_personal_snippet,
          :admin_personal_snippet
        ]
      end

      if snippet.public? || (snippet.internal? && !user.external?)
        rules << :read_personal_snippet
      end

      rules
    end

    def project_snippet_abilities(user, snippet)
      rules = []

      if snippet.author == user || user.admin?
        rules += [
          :read_project_snippet,
          :update_project_snippet,
          :admin_project_snippet
        ]
      end

      if snippet.public? || (snippet.internal? && !user.external?) || (snippet.private? && snippet.project.team.member?(user))
        rules << :read_project_snippet
      end

      rules
    end

    def group_member_abilities(user, subject)
      rules = []
      target_user = subject.user
      group = subject.group

      unless group.last_owner?(target_user)
        can_manage = group_abilities(user, group).include?(:admin_group_member)

        if can_manage
          rules << :update_group_member
          rules << :destroy_group_member
        elsif user == target_user
          rules << :destroy_group_member
        end
      end

      rules
    end

    def project_member_abilities(user, subject)
      rules = []
      target_user = subject.user
      project = subject.project

      unless target_user == project.owner
        can_manage = project_abilities(user, project).include?(:admin_project_member)

        if can_manage
          rules << :update_project_member
          rules << :destroy_project_member
        elsif user == target_user
          rules << :destroy_project_member
        end
      end

      rules
    end

    def commit_status_abilities(user, subject)
      rules = project_abilities(user, subject.project)
      # If subject is Ci::Build which inherits from CommitStatus filter the abilities
      rules = filter_build_abilities(rules) if subject.is_a?(Ci::Build)
      rules
    end

    def filter_build_abilities(rules)
      # If we can't read build we should also not have that
      # ability when looking at this in context of commit_status
      %w(read create update admin).each do |rule|
        rules.delete(:"#{rule}_commit_status") unless rules.include?(:"#{rule}_build")
      end
      rules
    end

    def runner_abilities(user, runner)
      if user.is_admin?
        [:assign_runner]
      elsif runner.is_shared? || runner.locked?
        []
      elsif user.ci_authorized_runners.include?(runner)
        [:assign_runner]
      else
        []
      end
    end

    def abilities
      @abilities ||= begin
        abilities = Six.new
        abilities << self
        abilities
      end
    end

    private

    def named_abilities(name)
      [
        :"read_#{name}",
        :"create_#{name}",
        :"update_#{name}",
        :"admin_#{name}"
      ]
    end

    def filter_confidential_issues_abilities(user, issue, rules)
      return rules if user.admin? || !issue.confidential?

      unless issue.author == user || issue.assignee == user || issue.project.team.member?(user, Gitlab::Access::REPORTER)
        rules.delete(:admin_issue)
        rules.delete(:read_issue)
        rules.delete(:update_issue)
      end

      rules
    end
  end
end
