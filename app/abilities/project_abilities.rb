class ProjectAbilities < Abilities
  def self.abilities(user, subject)
    if anonymous?(user)
      anonymous_abilities(subject)
    # FIXME (rspeicher): This is dumb and we don't want to have to add this
    # check to every single Abilities class. Move it higher up.
    elsif blocked?(user)
      []
    else
      authenticated_abilities(user, subject)
    end
  end

  # FIXME (rspeicher): The following methods should be private but are called
  # directly in spec/models/project_security_spec.rb

  def self.project_team_rules(team, user)
    # Rules based on role in project
    if team.master?(user)
      project_master_rules
    elsif team.developer?(user)
      project_dev_rules
    elsif team.reporter?(user)
      project_report_rules
    elsif team.guest?(user)
      project_guest_rules
    else
      []
    end
  end

  def self.project_dev_rules
    @project_dev_rules ||= project_report_rules + [
      :admin_merge_request,
      :update_merge_request,
      :create_commit_status,
      :update_commit_status,
      :create_build,
      :update_build,
      :create_pipeline,
      :update_pipeline,
      :create_merge_request,
      :create_wiki,
      :push_code,
      :create_container_image,
      :update_container_image,
      :create_environment,
      :create_deployment
    ]
  end

  def self.project_master_rules
    @project_master_rules ||= project_dev_rules + [
      :push_code_to_protected_branches,
      :update_project_snippet,
      :update_environment,
      :update_deployment,
      :admin_milestone,
      :admin_project_snippet,
      :admin_project_member,
      :admin_merge_request,
      :admin_note,
      :admin_wiki,
      :admin_project,
      :admin_commit_status,
      :admin_build,
      :admin_container_image,
      :admin_pipeline,
      :admin_environment,
      :admin_deployment
    ]
  end

  def self.project_owner_rules
    @project_owner_rules ||= project_master_rules + [
      :change_namespace,
      :change_visibility_level,
      :rename_project,
      :remove_project,
      :archive_project,
      :remove_fork_project,
      :destroy_merge_request,
      :destroy_issue
    ]
  end

  def self.project_report_rules
    @project_report_rules ||= project_guest_rules + [
      :download_code,
      :fork_project,
      :create_project_snippet,
      :update_issue,
      :admin_issue,
      :admin_label,
      :read_commit_status,
      :read_build,
      :read_container_image,
      :read_pipeline,
      :read_environment,
      :read_deployment
    ]
  end

  def self.project_guest_rules
    @project_guest_rules ||= [
      :read_project,
      :read_wiki,
      :read_issue,
      :read_label,
      :read_milestone,
      :read_project_snippet,
      :read_project_member,
      :read_merge_request,
      :read_note,
      :create_project,
      :create_issue,
      :create_note,
      :upload_file
    ]
  end

  def self.project_archived_rules
    @project_archived_rules ||= [
      :create_merge_request,
      :push_code,
      :push_code_to_protected_branches,
      :update_merge_request,
      :admin_merge_request
    ]
  end

  def self.public_project_rules
    @public_project_rules ||= project_guest_rules + [
      :download_code,
      :fork_project,
      :read_commit_status,
      :read_pipeline
    ]
  end

  private

  def self.anonymous_abilities(subject)
    project = if subject.is_a?(Project)
                subject
              else
                subject.project
              end

    if project && project.public?
      rules = [
        :read_project,
        :read_wiki,
        :read_label,
        :read_milestone,
        :read_project_snippet,
        :read_project_member,
        :read_merge_request,
        :read_note,
        :read_pipeline,
        :read_commit_status,
        :read_container_image,
        :download_code
      ]

      # Allow to read builds by anonymous user if guests are allowed
      rules << :read_build if project.public_builds?

      # Allow to read issues by anonymous user if issue is not confidential
      rules << :read_issue unless subject.is_a?(Issue) && subject.confidential?

      rules - project_disabled_features_rules(project)
    else
      []
    end
  end

  def self.authenticated_abilities(user, project)
    rules = []
    key = "/user/#{user.id}/project/#{project.id}"

    RequestStore.store[key] ||= begin
      # Push abilities on the users team role
      rules.push(*project_team_rules(project.team, user))

      owner = user.admin? ||
              project.owner == user ||
              (project.group && project.group.has_owner?(user))

      if owner
        rules.push(*project_owner_rules)
      end

      if project.public? || (project.internal? && !user.external?)
        rules.push(*public_project_rules)

        # Allow to read builds for internal projects
        rules << :read_build if project.public_builds?

        unless owner || project.team.member?(user) || project_group_member?(project, user)
          rules << :request_access
        end
      end

      if project.archived?
        rules -= project_archived_rules
      end

      rules - project_disabled_features_rules(project)
    end
  end

  def self.project_disabled_features_rules(project)
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

  def self.project_group_member?(project, user)
    project.group &&
      (
        project.group.members.exists?(user_id: user.id) ||
        project.group.requesters.exists?(user_id: user.id)
      )
  end
end
