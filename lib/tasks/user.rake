# frozen_string_literal: true

namespace :user do
  desc 'Send out monthly download statistics email'
  task monthly_stats_email: :environment do
    Rails.logger.info('Starting monthly stats task...')
    User.where(provider: 'azure_oauth', opt_out_stats_email: false, active: true).each do |user|
      Rails.logger.info("Putting Job on the queue for #{user.actor.email}")
      ActorMailer.with(actor: user.actor).monthly_stats.deliver_later
    end
    Rails.logger.info('Monthly stats task is complete.')
  end
end
