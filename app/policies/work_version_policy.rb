# frozen_string_literal: true

class WorkVersionPolicy < ApplicationPolicy
  class Scope < Scope
    def limit
      scope.all
    end
  end

  def show?
    Pundit.policy(user, record.work).show? || editable?
  end
  alias_method :diff?, :show?

  def edit?
    return false if record.published? && !user.admin?

    editable?
  end
  alias_method :update?, :edit?

  # Work versions cannot be destroyed if they haven't been persisted.
  # Admins can delete a work version in any state, as long as it's the latest one
  # Regular users can only delete draft versions that they can edit
  def destroy?
    return false if record.new_record?
    return true if user.admin? && record == record.work.latest_version

    !record.published? && editable?
  end

  def publish?
    return false if record.published?

    editable?
  end

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
