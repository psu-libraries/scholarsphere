# frozen_string_literal: true

class Dashboard::WorkVersionPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope.all
    end
  end

  def show?
    owner?
  end

  def edit?
    record.draft? && owner?
  end

  alias_method :update?, :edit?
  alias_method :delete?, :edit?

  def new?(latest_version)
    record.published? && record == latest_version
  end

  private

    def owner?
      user == record.depositor
    end
end
