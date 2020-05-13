# frozen_string_literal: true

# @note this is a policy used by the public-facing side of the app. The
# Dashboard (where users work on their own stuff) has a different policy. At
# some point we may combine the two, but don't want to prefactor
class CollectionPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope.all
    end
  end

  def show?
    record.read_access? user
  end
end
