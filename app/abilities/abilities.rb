class Abilities
  def self.anonymous?(user)
    user.nil?
  end

  def self.blocked?(user)
    user && user.try(:blocked?)
  end

  # TODO (rspeicher): DRY
  def self.named_abilities(name)
    %W(
      read_#{name}
      create_#{name}
      update_#{name}
      admin_#{name}
    )
  end
end
