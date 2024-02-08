# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AdminContactDepositor, type: :model do
  subject { build(:admin_contact_depositor) }

  describe '::attributes' do
    it { is_expected.to respond_to(:send_to_name) }
    it { is_expected.to respond_to(:send_to_email) }
    it { is_expected.to respond_to(:subject) }
    it { is_expected.to respond_to(:message) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:send_to_name) }
    it { is_expected.to validate_presence_of(:subject) }
    it { is_expected.to validate_presence_of(:message) }

    context 'with a valid send_to_email' do
      it { is_expected.to be_valid }
    end

    context 'with a bogus send_to_email' do
      subject { build(:admin_contact_depositor, send_to_email: 'notanemail') }

      it { is_expected.not_to be_valid }
    end
  end
end
