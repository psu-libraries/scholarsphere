# frozen_string_literal: true

# Preview all emails at http://localhost:3000/rails/mailers/auto_remediation_mailer
class AutoRemediationMailerPreview < ActionMailer::Preview
  def remediated_version_created
    AutoRemediationMailer.with(
      contributor_email: 'contributor@example.com',
      work_title: 'Example Work Title',
      work_version_uuid: '123e4567-e89b-12d3-a456-426614174000'
    ).remediated_version_created
  end
end
