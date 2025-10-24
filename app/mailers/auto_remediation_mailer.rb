# frozen_string_literal: true

class AutoRemediationMailer < ApplicationMailer
  def remediated_version_created
    contributor_email = params[:contributor_email]

    @work_title = params[:work_title]
    @work_version_uuid = params[:work_version_uuid]

    mail(
      to: contributor_email,
      from: Rails.configuration.no_reply_email,
      subject: I18n.t('mailers.auto_remediation.remediated_version_created.subject')
    )
  end
end
