# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AutoRemediationNotifications do
  subject(:service) { described_class.new(work_version) }

  let(:work_title) { 'Remediated Work' }
  let(:work_uuid)  { 'wv-123' }

  let(:creator_email_a) { 'creator-a@example.org' }
  let(:creator_email_b) { 'creator-b@example.org' }

  let(:creator_with_email_a)  { instance_double('Creator', email: creator_email_a) }
  let(:creator_with_email_b)  { instance_double('Creator', email: creator_email_b) }
  let(:creator_with_nil)      { instance_double('Creator', email: nil) }
  let(:creator_dup_email_a)   { instance_double('Creator', email: creator_email_a) } # duplicate of A

  let(:depositor_email_dup_b) { creator_email_b } # depositor duplicates creator B
  let(:depositor)             { instance_double('User', email: depositor_email_dup_b) }

  let(:work_version) do
    instance_double(
      'WorkVersion',
      title: work_title,
      uuid: work_uuid,
      creators: [creator_with_email_a, creator_with_email_b, creator_with_nil, creator_dup_email_a],
      depositor: depositor
    )
  end

  it 'sends to unique, non-nil creator emails plus the depositor (deduped)' do
    expected_emails = [creator_email_a, creator_email_b].sort
    mailer_proxy = instance_double('MailerProxy')
    message      = instance_double(ActionMailer::MessageDelivery, deliver_later: true)
    allow(mailer_proxy)
      .to receive(:remediated_version_created)
      .and_return(message)

    expected_emails.each do |email|
      allow(AutoRemediationMailer)
        .to receive(:with)
        .with(work_version_title: work_title,
              work_version_uuid: work_uuid,
              contributor_email: email)
        .and_return(mailer_proxy)
    end

    service.send_notifications

    expect(AutoRemediationMailer)
      .to have_received(:with).exactly(expected_emails.size).times

    expect(mailer_proxy)
      .to have_received(:remediated_version_created).exactly(expected_emails.size).times

    expected_emails.each do |email|
      expect(AutoRemediationMailer)
        .to have_received(:with)
        .with(work_version_title: work_title,
              work_version_uuid: work_uuid,
              contributor_email: email)
    end
  end

  context 'when there are no emails' do
    let(:work_version) do
      instance_double(
        'WorkVersion',
        title: work_title,
        uuid: work_uuid,
        creators: [instance_double('Creator', email: nil)],
        depositor: instance_double('User', email: nil)
      )
    end

    it 'does not attempt to send any email' do
      allow(AutoRemediationMailer).to receive(:with)
      service.send_notifications
      expect(AutoRemediationMailer).not_to have_received(:with)
    end
  end
end
