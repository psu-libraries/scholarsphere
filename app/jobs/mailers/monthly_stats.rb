# frozen_string_literal: true

module Mailers
  class MonthlyStats < ApplicationJob
    queue_as :mailers

    def perform
      User.includes(:actor).where(provider: 'azure_oauth', opt_out_stats_email: false, active: true).find_each do |user|
        ActorMailer.with(actor: user.actor).monthly_stats.deliver_later
      end
    end
  end
end
