# frozen_string_literal: true

class CollectionPolicy < ApplicationPolicy
  class Scope < Scope
    def limit
      scope.where(depositor: user.actor)
    end
  end

  def show?
    record.discover_access?(user) || edit?
  end

  def edit?
    owner? || record.edit_access?(user) || user.admin?
  end
  alias_method :create?, :edit?
  alias_method :update?, :edit?
  alias_method :destroy?, :edit?
  alias_method :mint_doi?, :edit?

  private

    def owner?
      record.depositor == user.actor
    end
end
