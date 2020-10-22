# frozen_string_literal: true

class ActorPolicy < ApplicationPolicy
  class Scope < Scope
    def limit
      scope.all
    end
  end

  def create?
    !user.guest?
  end

  alias_method :new?, :create?
  alias_method :show?, :create?
end
