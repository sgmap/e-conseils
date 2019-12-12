class ApplicationPolicy
  attr_reader :context, :params

  def initialize(context, record)
    @context = context
    @record = record
  end

  delegate :user, to: :context
  delegate :expert, to: :context

  def index?
    true
  end

  def show?
    false
  end

  def create?
    true
  end

  def new?
    create?
  end

  def update?
    false
  end

  def edit?
    update?
  end

  def destroy?
    false
  end

  def support?(user, diagnosis)
    user&.experts.any? do |expert|
      return true if expert.experts_subjects.support_for(diagnosis).present?
    end
  end

  def admin?
    user&.is_admin
  end

  class Scope
    attr_reader :user, :scope

    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    def resolve
      scope.all
    end
  end
end
