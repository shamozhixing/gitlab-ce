class BasePolicy
  def initialize(subject)
    @subject = subject
  end

  def abilities(user)
    return anonymous_abilities if user.nil?
    collect_rules { rules(user) }
  end

  def anonymous_abilities
    collect_rules { anonymous_rules }
  end

  def generate!
    raise 'abstract'
  end

  def can!(*rules)
    @can.merge(rules)
  end

  def cannot!(*rules)
    @cannot.merge(rules)
  end

  private

  def collect_rules(&b)
    return Set.new if @subject.nil?

    @can = Set.new
    @cannot = Set.new
    yield
    @can - @cannot
  end
end
