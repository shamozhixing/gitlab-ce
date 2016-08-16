class NotePolicy < BasePolicy
  def rules
    delegate! @subject.project

    if @user && @subject.author == @user
      can! :read_note
      can! :update_note
      can! :admin_note
    end
  end
end
