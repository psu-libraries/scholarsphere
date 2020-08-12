# frozen_string_literal: true

namespace :user do
  desc 'Send out monthly download statistics email'
  task monthly_stats_email: :environment do
    User.where(provider: 'azure_oauth', opt_out_stats_email: false, active: true).each do |user|
      ActorMailer.with(actor: user.actor).monthly_stats.deliver_later
    end
  end
end
