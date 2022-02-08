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

  def added_as_editor
    @actor = params[:actor]
    @resource = params[:resource]
    @decorated_resource = ResourceDecorator.decorate(@resource)

    mail(
      to: @actor.email,
      from: Rails.configuration.contact_email,
      subject: ::I18n.t('mailers.actor.added_as_editor.subject', title: @decorated_resource.title.truncate(30))
    )
  end
end
