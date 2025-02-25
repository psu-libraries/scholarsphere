# frozen_string_literal: true

require 'rails_helper'

RSpec.describe IncidentMailer do
  describe '#report' do
    subject(:mail) { described_class.report(incident) }

    context 'with a valid incident' do
      let(:incident) { build(:incident, subject: 'Apollo 13', message: 'Houston, we have a problem') }

      it 'sends the email' do
        expect(mail.subject).to eq('ScholarSphere Contact Form - Apollo 13')
        expect(mail.body.raw_source).to match('Houston, we have a problem')
      end
    end

    context 'with an invalid incident' do
      let(:incident) { build(:incident, email: 'bogus') }

      its(:message) { is_expected.to be_a(ActionMailer::Base::NullMail) }
    end
  end

  describe '#acknowledgment' do
    subject(:mail) { described_class.acknowledgment(incident) }

    context 'with a Penn State email address' do
      let(:incident) { build(:incident, :from_penn_state) }

      it 'sends an acknowledgment email to the user who reported the incident' do
        expect(mail.to).to eq([incident.email])
        expect(mail.subject).to eq("#{Rails.configuration.subject_prefix} #{incident.subject}")
        expect(mail.body.raw_source).to match(/Thank you for contacting us with your question/)
      end
    end

    context 'with a non-Penn State email address' do
      let(:incident) { build(:incident) }

      its(:message) { is_expected.to be_a(ActionMailer::Base::NullMail) }
    end
  end
end
