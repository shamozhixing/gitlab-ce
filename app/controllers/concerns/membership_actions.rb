module MembershipActions
  extend ActiveSupport::Concern

  def request_access
    Members::RequestAccessService.new(membershipable, current_user).execute

    redirect_to polymorphic_path(membershipable),
                notice: 'Your request for access has been queued for review.'
  end

  def approve_access_request
    Members::ApproveAccessRequestService.new(membershipable, current_user, user_id: params[:id]).execute

    redirect_to polymorphic_url([membershipable, :members])
  end

  def leave
    Members::DestroyService.new(membershipable, current_user, user_id: current_user.id).execute(:all)

    source_type = membershipable.class.to_s.humanize(capitalize: false)
    notice =
      if @member.request?
        "Your access request to the #{source_type} has been withdrawn."
      else
        "You left the \"#{membershipable.human_name}\" #{source_type}."
      end
    redirect_path = @member.request? ? @member.source : [:dashboard, membershipable.class.to_s.tableize]

    redirect_to redirect_path, notice: notice
  end

  protected

  def membershipable
    raise NotImplementedError
  end
end
