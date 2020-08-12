# frozen_string_literal: true

# Preview all emails at http://localhost:3000/rails/mailers/actor_mailer
class ActorMailerPreview < ActionMailer::Preview
  def monthly_stats
    ActorMailer.with(actor: Actor.first).monthly_stats
  end
end
