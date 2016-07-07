class UserAbilities < Abilities
  def self.abilities(user, subject)
    if anonymous?(user)
      anonymous_abilities(subject)
    else
      authenticated_abilities(user, subject)
    end
  end

  private

  def self.anonymous_abilities(subject)
    authenticated_abilities(nil, subject) unless restricted_public_level?
  end

  def self.authenticated_abilities(_user, _subject)
    [:read_user]
  end

  def self.restricted_public_level?
    current_application_settings
      .restricted_visibility_levels
      .include?(Gitlab::VisibilityLevel::PUBLIC)
  end
end
