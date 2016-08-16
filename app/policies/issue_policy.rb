class IssuePolicy < IssuablePolicy
  def issue
    @subject
  end

  def rules
    super

    cannot! :read_issue if @subject.confidential? && !can_read_confidential?
  end

  private
  def can_read_confidential?
    return false unless @user
    return true if @user.admin?
    return true if @subject.author == @user
    return true if @subject.assignee == @user
    return true if @subject.project.team.member?(@user, Gitlab::Access::REPORTER)
    false
  end
end
