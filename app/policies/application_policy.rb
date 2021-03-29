# frozen_string_literal: true

class ApplicationPolicy
  attr_reader :user, :record

  # @param [User, UserDecorator] user
  # @param [ActiveRecord::Base] record
  def initialize(user, record)
    @user = user.try(:to_model) || user
    @record = record
  end

  def index?
    user.admin?
  end

  def show?
    user.admin?
  end

  def create?
    user.admin?
  end

  def new?
    create?
  end

  def update?
    user.admin?
  end

  def edit?
    update?
  end

  def destroy?
    user.admin?
  end

  class Scope
    attr_reader :user, :scope

    def initialize(user, scope)
      raise NoMethodError, "#{self.class}#limit must be defined instead of #resolve" unless respond_to?(:limit)

      @user = user
      @scope = scope
    end

    def resolve
      return scope.all if user.admin?

      limit
    end
  end
end
