# frozen_string_literal: true

require 'rails_helper'

RSpec.describe WorkVersion, type: :model do
  describe 'table' do
    it { is_expected.to have_db_column(:work_id) }
    it { is_expected.to have_db_column(:version_name) }
    it { is_expected.to have_db_index(:work_id) }
    it { is_expected.to have_db_column(:aasm_state) }
    it { is_expected.to have_db_column(:metadata).of_type(:jsonb) }
    it { is_expected.to have_db_column(:uuid).of_type(:uuid) }
    it { is_expected.to have_jsonb_accessor(:title).of_type(:string) }
    it { is_expected.to have_jsonb_accessor(:subtitle).of_type(:string) }
    it { is_expected.to have_jsonb_accessor(:keywords).of_type(:string).is_array.with_default([]) }
    it { is_expected.to have_jsonb_accessor(:rights).of_type(:string) }
    it { is_expected.to have_jsonb_accessor(:description).of_type(:string) }
    it { is_expected.to have_jsonb_accessor(:resource_type).of_type(:string) }
    it { is_expected.to have_jsonb_accessor(:contributor).of_type(:string) }
    it { is_expected.to have_jsonb_accessor(:publisher).of_type(:string) }
    it { is_expected.to have_jsonb_accessor(:published_date).of_type(:string) }
    it { is_expected.to have_jsonb_accessor(:subject).of_type(:string) }
    it { is_expected.to have_jsonb_accessor(:language).of_type(:string) }
    it { is_expected.to have_jsonb_accessor(:identifier).of_type(:string) }
    it { is_expected.to have_jsonb_accessor(:based_near).of_type(:string) }
    it { is_expected.to have_jsonb_accessor(:related_url).of_type(:string) }
    it { is_expected.to have_jsonb_accessor(:source).of_type(:string) }
  end

  describe 'factory' do
    it { is_expected.to have_valid_factory(:work_version) }
  end

  describe 'associations' do
    it { is_expected.to belong_to(:work) }
    it { is_expected.to have_many(:file_version_memberships) }
    it { is_expected.to have_many(:file_resources).through(:file_version_memberships) }

    it { is_expected.to accept_nested_attributes_for(:file_resources) }
  end

  describe 'states' do
    it { is_expected.to have_state(:draft) }
    it { is_expected.to transition_from(:draft).to(:published).on_event(:publish) }
    it { is_expected.to transition_from(:published).to(:withdrawn).on_event(:withdraw) }
    it { is_expected.to transition_from(:withdrawn).to(:published).on_event(:publish) }
    it { is_expected.to transition_from(:draft).to(:removed).on_event(:remove) }
    it { is_expected.to transition_from(:withdrawn).to(:removed).on_event(:remove) }
  end

  describe 'validations' do
    subject(:work_version) { described_class.new }

    context 'when draft' do
      it { is_expected.to validate_presence_of(:title) }
    end

    context 'when published' do
      before { work_version.publish }

      it { is_expected.to validate_presence_of(:title) }

      it 'validates the presence files' do
        work_version.file_resources = []
        work_version.validate
        expect(work_version.errors[:file_resources]).not_to be_empty
        work_version.file_resources.build
        work_version.validate
        expect(work_version.errors[:file_resources]).to be_empty
      end
    end
  end

  describe 'indexing' do
    subject { SolrDocument.find(work_version.uuid) }

    let(:work_version) { create(:work_version) }

    its(:to_h) do
      is_expected.to include(
        'title_tesi' => work_version.title,
        'id' => work_version.uuid,
        'model_ssi' => 'WorkVersion'
      )
    end
  end

  it { is_expected.to delegate_method(:depositor).to(:work) }

  describe '#keywords=' do
    subject { described_class.new(keywords: ['', 'thing']) }

    its(:keywords) { is_expected.to contain_exactly('thing') }
  end

  describe '#uuid' do
    subject { create(:work_version) }

    its(:uuid) { is_expected.to match(/[a-z0-9]{8}-[a-z0-9]{4}-[a-z0-9]{4}-[a-z0-9]{4}-[a-z0-9]{12}/) }
  end
end
