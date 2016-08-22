module MergeRequestsHelper
  def new_mr_path_from_push_event(event)
    target_project = event.project.forked_from_project || event.project
    new_namespace_project_merge_request_path(
      event.project.namespace,
      event.project,
      new_mr_from_push_event(event, target_project)
    )
  end

  def new_mr_from_push_event(event, target_project)
    {
      merge_request: {
        source_project_id: event.project.id,
        target_project_id: target_project.id,
        source_branch: event.branch_name,
        target_branch: target_project.repository.root_ref
      }
    }
  end

  def mr_css_classes(mr)
    classes = "merge-request"
    classes << " closed" if mr.closed?
    classes << " merged" if mr.merged?
    classes
  end

  def ci_build_details_path(merge_request)
    build_url = merge_request.source_project.ci_service.build_page(merge_request.diff_head_sha, merge_request.source_branch)
    return nil unless build_url

    parsed_url = URI.parse(build_url)

    unless parsed_url.userinfo.blank?
      parsed_url.userinfo = ''
    end

    parsed_url.to_s
  end

  def merge_path_description(merge_request, separator)
    if merge_request.for_fork?
      "Project:Branches: #{@merge_request.source_project_path}:#{@merge_request.source_branch} #{separator} #{@merge_request.target_project.path_with_namespace}:#{@merge_request.target_branch}"
    else
      "Branches: #{@merge_request.source_branch} #{separator} #{@merge_request.target_branch}"
    end
  end

  def issues_sentence(issues)
    # Sorting based on the `#123` or `group/project#123` reference will sort
    # local issues first.
    issues.map do |issue|
      issue.to_reference(@project)
    end.sort.to_sentence
  end

  def mr_closes_issues
    @mr_closes_issues ||= @merge_request.closes_issues
  end

  def mr_change_branches_path(merge_request)
    new_namespace_project_merge_request_path(
      @project.namespace, @project,
      merge_request: {
        source_project_id: @merge_request.source_project_id,
        target_project_id: @merge_request.target_project_id,
        source_branch: @merge_request.source_branch,
        target_branch: @merge_request.target_branch,
      },
      change_branches: true
    )
  end

  def source_branch_with_namespace(merge_request)
    branch = link_to(merge_request.source_branch, namespace_project_commits_path(merge_request.source_project.namespace, merge_request.source_project, merge_request.source_branch))

    if merge_request.for_fork?
      namespace = link_to(merge_request.source_project_namespace,
        project_path(merge_request.source_project))
      namespace + ":" + branch
    else
      branch
    end
  end

  def format_mr_branch_names(merge_request)
    source_path = merge_request.source_project_path
    target_path = merge_request.target_project_path
    source_branch = merge_request.source_branch
    target_branch = merge_request.target_branch

    if source_path == target_path
      [source_branch, target_branch]
    else
      ["#{source_path}:#{source_branch}", "#{target_path}:#{target_branch}"]
    end
  end

  def merge_request_button_visibility(merge_request, closed)
    return 'hidden' if merge_request.closed? == closed || (merge_request.merged? == closed && !merge_request.closed?)
  end

  def widget_options
    {
      merge_check_url: merge_check_namespace_project_merge_request_path(@project.namespace, @project, @merge_request),
      check_enable: (@merge_request.unchecked? ? 'true' : 'false'),
      ci_status_url: ci_status_namespace_project_merge_request_path(@project.namespace, @project, @merge_request),
      gitlab_icon: asset_path('gitlab_logo.png'),
      ci_status: (@merge_request.pipeline ? @merge_request.pipeline.status : ''),
      ci_message: {
        normal: 'Build {{status}} for "{{title}}"',
        preparing: '{{status}} build for "{{title}}"'
      },
      ci_enable: (@project.ci_service ? 'true' : 'false'),
      ci_title: {
        preparing: "{{status}} build",
        normal: "Build {{status}}"
      },
      builds_path: builds_namespace_project_merge_request_path(@project.namespace, @project, @merge_request),
      pipelines_path: pipelines_namespace_project_merge_request_path(@project.namespace, @project, @merge_request),
      merge_path: merge_namespace_project_merge_request_path(@project.namespace, @project, @merge_request),
      remove_path: namespace_project_branch_path(@merge_request.source_project.namespace, @merge_request.source_project, @merge_request.source_branch),
      cancel_merge_on_success_path: cancel_merge_when_build_succeeds_namespace_project_merge_request_path(@merge_request.target_project.namespace, @merge_request.target_project, @merge_request),
      check_status: (@merge_request.open? && @merge_request.unchecked? ? 'true' : 'false')
    }
  end
end
