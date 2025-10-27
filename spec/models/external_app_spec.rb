# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ExternalApp do
  describe 'table' do
    it { is_expected.to have_db_column(:name).of_type(:string) }
    it { is_expected.to have_db_column(:contact_email).of_type(:string) }

    it { is_expected.to have_db_index(:name) }
  end

  describe 'factories' do
    it { is_expected.to have_valid_factory(:external_app) }
  end

  describe 'associations' do
    it { is_expected.to have_many(:api_tokens) }
    it { is_expected.to have_many(:work_versions).dependent(:nullify) }
  end

  describe 'validations' do
    it { is_expected.to validate_uniqueness_of(:name) }
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:contact_email) }
  end

  describe '::metadata_listener' do
    subject(:app) { described_class.metadata_listener }

    it { is_expected.to be_a(described_class) }
    its(:token) { is_expected.to eq(app.api_tokens.first.token) }
    its(:contact_email) { is_expected.to eq(Rails.configuration.no_reply_email) }
  end

  describe '::pdf_accessibility_api' do
    subject(:app) { described_class.pdf_accessibility_api }

    it { is_expected.to be_a(described_class) }
    its(:contact_email) { is_expected.to eq(Rails.configuration.no_reply_email) }
  end

  describe '#access_id' do
    subject(:application) { build(:external_app) }

    its(:access_id) { is_expected.to eq(application.name) }
  end

  describe '#guest?' do
    it { is_expected.not_to be_guest }
  end

  describe '#admin?' do
    it { is_expected.to be_admin }
  end

  describe '#actor' do
    its(:actor) { is_expected.to be_a(NullActor) }
  end
end
