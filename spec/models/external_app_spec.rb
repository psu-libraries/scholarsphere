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
    # It is preferable to use `token` with ExternalApps that use the API
    its(:token) { is_expected.to eq(app.api_tokens.first.token) }
    its(:webhook_token) { is_expected.to eq(app.api_tokens.first.token) }
    its(:contact_email) { is_expected.to eq(Rails.configuration.no_reply_email) }
  end

  describe '::pdf_accessibility_api' do
    subject(:app) { described_class.pdf_accessibility_api }

    it { is_expected.to be_a(described_class) }
    its(:token) { is_expected.to eq(app.api_tokens.first.token) }
    # It is preferable to use `webhook_token` with ExternalApps that use webhooks
    its(:webhook_token) { is_expected.to eq(app.api_tokens.first.token) }
    its(:contact_email) { is_expected.to eq(Rails.configuration.no_reply_email) }
  end

  describe '::researcher_metadata_database' do
    subject(:app) { described_class.researcher_metadata_database }

    it { is_expected.to be_a(described_class) }

    context 'when the application does not exist yet' do
      before do
        described_class.where(name: 'Researcher Metadata Database').delete_all
      end

      its(:token) { is_expected.to eq(app.api_tokens.first.token) }
      its(:contact_email) { is_expected.to eq(Rails.configuration.no_reply_email) }
    end

    context 'when the application already exists' do
      let!(:existing_app) do
        create(:external_app,
               name: 'Researcher Metadata Database',
               contact_email: 'existing_contact@example.com')
      end

      it 'does not create a duplicate external app' do
        expect { app }.not_to(change(described_class, :count))
      end

      it 'returns the existing external app without mutating attributes' do
        expect(app.id).to eq(existing_app.id)
        expect(existing_app.reload.contact_email).to eq('existing_contact@example.com')
      end

      it 'does not backfill an api token for an existing app' do
        expect { app }.not_to(change(ApiToken, :count))
        expect(existing_app.reload.api_tokens).to be_empty
      end
    end
  end

  describe '#access_id' do
    subject(:application) { build(:external_app) }

    its(:access_id) { is_expected.to eq(application.name) }
  end

  describe '#researcher_metadata_database?' do
    subject(:application) { build(:external_app, name:) }

    context 'when the app is Researcher Metadata Database' do
      let(:name) { ExternalApp::ResearcherMetadataDatabase::NAME }

      it { is_expected.to be_researcher_metadata_database }
    end

    context 'when the app is not Researcher Metadata Database' do
      let(:name) { 'Another External App' }

      it { is_expected.not_to be_researcher_metadata_database }
    end
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
