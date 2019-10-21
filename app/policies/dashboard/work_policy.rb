# frozen_string_literal: true

class Dashboard::WorkPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope.all
    end
  end

  def create_version?
    owner? && record.draft_version.blank?
  end

  private

    def owner?
      user == record.depositor
    end
end
