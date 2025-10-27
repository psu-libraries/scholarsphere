# frozen_string_literal: true

class AutoRemediationNotifications
  def initialize(remediated_work_version)
    @remediated_work_version = remediated_work_version
  end

  def send_notifications
    contributors_emails.each do |email|
      AutoRemediationMailer
        .with(work_version_title: @remediated_work_version.title,
              work_version_uuid: @remediated_work_version.uuid,
              contributor_email: email)
        .remediated_version_created
        .deliver_later
    end
  end

  private

    attr_reader :remediated_work_version

    def contributors_emails
      [remediated_work_version.creators.map(&:email) + [remediated_work_version.depositor.email]]
        .flatten
        .compact
        .uniq
    end
end
