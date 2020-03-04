# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ApiToken, type: :model do
  describe 'table' do
    it { is_expected.to have_db_column(:token).of_type(:string) }
    it { is_expected.to have_db_column(:app_name).of_type(:string) }
    it { is_expected.to have_db_column(:admin_email).of_type(:string) }
    it { is_expected.to have_db_column(:last_used_at).of_type(:datetime) }
    it { is_expected.to have_db_column(:created_at).of_type(:datetime) }
    it { is_expected.to have_db_column(:updated_at).of_type(:datetime) }

    it { is_expected.to have_db_index(:token).unique(true) }
  end

  describe 'factory' do
    it { is_expected.to have_valid_factory(:api_token) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:app_name) }
    it { is_expected.to validate_presence_of(:admin_email) }
  end

  describe 'creating a new token' do
    let(:new_token) { build :api_token, token: nil }

    it 'sets a value for the token' do
      new_token.save!
      expect(new_token.token.length).to eq 96
    end
  end

  describe '#record_usage' do
    let(:token) { create :api_token }

    it 'touches last_used_at in the database' do
      expect {
        token.record_usage
      }.to(change {
        token.reload.last_used_at
      })
    end
  end
end
