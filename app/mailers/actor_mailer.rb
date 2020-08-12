# frozen_string_literal: true

class ActorMailer < ApplicationMailer
  def monthly_stats(month: Time.zone.now.last_month)
    @presenter = ActorStatsPresenter.new(
      actor: params[:actor],
      beginning_at: month.beginning_of_month,
      ending_at: month.end_of_month
    )
    return if @presenter.file_downloads.zero?

    mail(
      to: @presenter.actor.email,
      subject: ::I18n.t('mailers.actor.monthly_stats.subject')
    )
  end
end
