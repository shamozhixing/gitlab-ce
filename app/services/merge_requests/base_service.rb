module MergeRequests
  class BaseService < ::IssuableBaseService
    def create_note(merge_request)
      SystemNoteService.change_status(merge_request, merge_request.target_project, current_user, merge_request.state, nil)
    end

    def create_title_change_note(issuable, old_title)
      removed_wip = old_title =~ MergeRequest::WIP_REGEX && !issuable.work_in_progress?
      added_wip = old_title !~ MergeRequest::WIP_REGEX && issuable.work_in_progress?

      if removed_wip
        SystemNoteService.remove_merge_request_wip(issuable, issuable.project, current_user)
      elsif added_wip
        SystemNoteService.add_merge_request_wip(issuable, issuable.project, current_user)
      else
        super
      end
    end

    def hook_data(merge_request, action, oldrev = nil)
      hook_data = merge_request.to_hook_data(current_user)
      hook_data[:object_attributes][:url] = Gitlab::UrlBuilder.build(merge_request)
      hook_data[:object_attributes][:action] = action
      if oldrev && !Gitlab::Git.blank_ref?(oldrev)
        hook_data[:object_attributes][:oldrev] = oldrev
      end
      hook_data
    end

    def execute_hooks(merge_request, action = 'open', oldrev = nil)
      if merge_request.project
        merge_data = hook_data(merge_request, action, oldrev)
        merge_request.project.execute_hooks(merge_data, :merge_request_hooks)
        merge_request.project.execute_services(merge_data, :merge_request_hooks)
      end
    end

    private

    def filter_params
      super(:merge_request)
    end

    def merge_request_from(commit_status)
      branches = commit_status.ref

      # This is for ref-less builds
      branches ||= @project.repository.branch_names_contains(commit_status.sha)

      return [] if branches.blank?

      merge_requests = @project.origin_merge_requests.opened.where(source_branch: branches).to_a
      merge_requests += @project.fork_merge_requests.opened.where(source_branch: branches).to_a

      merge_requests.uniq.select(&:source_project)
    end

    def each_merge_request(commit_status)
      merge_request_from(commit_status).each do |merge_request|
        pipeline = merge_request.pipeline

        next unless pipeline
        next unless pipeline.sha == commit_status.sha

        yield merge_request, pipeline
      end
    end
  end
end
