# frozen_string_literal: true

class Dashboard::WorkPolicy < ApplicationPolicy
  class Scope < Scope
    def limit
      scope
        .where(depositor: user.actor)
        .or(scope.where(proxy_depositor: user.actor))
    end
  end

  def create_version?
    (owner? && record.draft_version.blank?) || user.admin?
  end

  private

    def owner?
      [
        record.depositor,
        record.proxy_depositor
      ].include? user.actor
    end
end
