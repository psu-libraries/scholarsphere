# frozen_string_literal: true

class Dashboard::CollectionPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope.where(depositor: user.actor)
    end
  end

  def show?
    owner?
  end

  alias_method :edit?, :show?
  alias_method :update?, :show?
  alias_method :destroy?, :show?

  private

    def owner?
      record.depositor == user.actor
    end
end
