# frozen_string_literal: true

class Dashboard::WorkVersionPolicy < WorkVersionPolicy
  class Scope < Scope
    def resolve
      scope
        .where(works: { depositor_id: user.actor_id })
        .or(scope.where(works: { proxy_id: user.actor_id }))
        .includes(:work)
    end
  end

  def show?
    owner?
  end

  def edit?
    record.draft? && owner?
  end

  alias_method :update?, :edit?
  alias_method :destroy?, :edit?
  alias_method :publish?, :edit?

  def new?(latest_version)
    record.published? && record == latest_version
  end

  private

    def owner?
      [record.depositor,
       record.proxy_depositor].include? user.actor
    end
end
