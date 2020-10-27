# frozen_string_literal: true

class WorkVersionPolicy < ApplicationPolicy
  class Scope < Scope
    def limit
      scope.all
    end
  end

  def show?
    Pundit.policy(user, record.work).show?
  end
  alias_method :diff?, :show?

  def edit?
    return false if record.published?

    editable?
  end
  alias_method :update?, :edit?
  alias_method :destroy?, :edit?
  alias_method :publish?, :edit?

  def download?
    return true if editable?
    return false if record.embargoed?

    record.work.read_access?(user) && record.published?
  end

  def new?
    Pundit.policy(user, record.work).create_version? &&
      record == record.work.latest_published_version
  end

  private

    def editable?
      Pundit.policy(user, record.work).edit?
    end
end
