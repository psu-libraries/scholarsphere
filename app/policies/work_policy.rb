# frozen_string_literal: true

# @note this is a policy used by the public-facing side of the app. The
# Dashboard (where users work on their own stuff) has a different policy. At
# some point we may combine the two, but don't want to prefactor
class WorkPolicy < ApplicationPolicy
  class Scope < Scope
    def limit
      scope.all
    end
  end

  def show?
    record.discover_access?(user) || user.admin?
  end

  def edit?
    editable?
  end

  private

    # @todo There's a bug in the permissions because a depositor should have edit access by default
    def editable?
      record.edit_access?(user) || record.depositor == user.actor || user.admin?
    end
end
