# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AdminContactDepositor, type: :model do
  subject { build(:admin_contact_depositor) }

  describe '::attributes' do
    it { is_expected.to respond_to(:send_to_name) }
    it { is_expected.to respond_to(:send_to_email) }
    it { is_expected.to respond_to(:subject) }
    it { is_expected.to respond_to(:validate_cc_email_to) }
    it { is_expected.to respond_to(:message) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:send_to_name) }
    it { is_expected.to validate_presence_of(:subject) }
    it { is_expected.to validate_presence_of(:message) }

    context 'with a valid send_to_email and cc_email_to' do
      it { is_expected.to be_valid }
    end

    context 'with a bogus send_to_email' do
      subject { build(:admin_contact_depositor, send_to_email: 'notanemail') }

      it { is_expected.not_to be_valid }
    end

    context 'with a cc_email_to that is not an Array' do
      subject { build(:admin_contact_depositor, cc_email_to: 'invalid datatype') }

      it { is_expected.not_to be_valid }
    end

    context 'with a cc_email_to has a bogus email' do
      subject { build(:admin_contact_depositor, cc_email_to: ['abc123']) }

      it { is_expected.not_to be_valid }
    end
  end
end
