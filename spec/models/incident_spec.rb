# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Incident do
  subject { build(:incident) }

  describe '::attributes' do
    it { is_expected.to respond_to(:category) }
    it { is_expected.to respond_to(:name) }
    it { is_expected.to respond_to(:email) }
    it { is_expected.to respond_to(:subject) }
    it { is_expected.to respond_to(:message) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:email) }
    it { is_expected.to validate_presence_of(:subject) }
    it { is_expected.to validate_presence_of(:message) }

    context 'with a valid email' do
      it { is_expected.to be_valid }
    end

    context 'with a bogus email' do
      subject { build(:incident, email: 'notanemail') }

      it { is_expected.not_to be_valid }
    end

    context 'with a bogus category' do
      subject { build(:incident, category: 'invalid category') }

      it { is_expected.not_to be_valid }
    end
  end

  describe '#headers' do
    subject(:incident) { build(:incident, subject: 'Test') }

    its(:headers) { is_expected.to eq(
      {
        from: incident.email,
        subject: 'ScholarSphere Contact Form - Test',
        to: Rails.configuration.incident_email
      }
    )}
  end
end
