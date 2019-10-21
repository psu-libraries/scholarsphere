# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Work, type: :model do
  describe 'table' do
    it { is_expected.to have_db_column(:work_type).of_type(:string) }
    it { is_expected.to have_db_column(:depositor_id) }
    it { is_expected.to have_db_index(:depositor_id) }
  end

  describe 'factories' do
    it { is_expected.to have_valid_factory(:work) }
  end

  describe 'associations' do
    it { is_expected.to belong_to(:depositor).class_name('User').with_foreign_key(:depositor_id) }
    it { is_expected.to have_many(:work_creations) }
    it { is_expected.to have_many(:aliases).through(:work_creations) }
    it { is_expected.to have_many(:access_controls) }
    it { is_expected.to have_many(:versions).class_name('WorkVersion').inverse_of('work') }

    it { is_expected.to accept_nested_attributes_for(:versions) }
  end

  describe 'validations' do
    it { is_expected.to validate_inclusion_of(:work_type).in_array(Work::Types.all) }
    it { is_expected.to validate_presence_of(:versions) }
  end

  describe '::Types' do
    subject(:types) { described_class::Types }

    describe '.all' do
      subject(:all) { types.all }

      it { is_expected.to match_array [types::DATASET] }
    end

    describe '.options_for_select_box' do
      subject(:options) { types.options_for_select_box }

      it { is_expected.to eq [['Dataset', types::DATASET]] }
    end

    describe '.display' do
      it 'returns a human-readable version of the type' do
        {
          types::DATASET => 'Dataset'
        }.each do |type, expected_output|
          expect(types.display(type)).to eq expected_output
        end
      end
    end
  end

  describe '.build_with_empty_version' do
    it 'builds a Work with one empty version' do
      work = described_class.build_with_empty_version
      expect(work.versions.length).to eq 1
    end

    it 'passes through any arguments provided' do
      work_type = described_class::Types.all.first
      work = described_class.build_with_empty_version(work_type: work_type)
      expect(work.versions).to be_present
      expect(work.work_type).to eq work_type
    end

    it 'will not overwrite a provided version' do
      versions = [WorkVersion.new]
      new_work = described_class.build_with_empty_version(versions: versions)
      expect(new_work.versions).to match_array(versions)
    end
  end

  describe 'initialize' do
    it 'does not initialize a work version too' do
      expect(described_class.new.versions).to be_empty
    end

    it 'accepts initial work versions' do
      versions = [WorkVersion.new]
      new_work = described_class.new(versions: versions)
      expect(new_work.versions).to match_array(versions)
    end
  end

  describe 'version accessors' do
    subject(:work) { create :work, versions: [draft, v2, v1] }

    let(:draft) { build :work_version, :draft, title: 'Draft', work: nil, created_at: 1.day.ago }
    let(:v2) { build :work_version, :published, title: 'Published v2', work: nil, created_at: 2.days.ago }
    let(:v1) { build :work_version, :published, title: 'Published v1', work: nil, created_at: 3.days.ago }

    before { work.reload }

    describe '#latest_version' do
      it 'returns the latest version regardless of status' do
        expect(work.latest_version.title).to eq draft.title
      end
    end

    describe '#latest_published_version' do
      it 'returns the latest published version' do
        expect(work.latest_published_version.title).to eq v2.title
      end
    end

    describe '#draft_version' do
      context 'when a draft exists' do
        its(:draft_version) { is_expected.to eq draft }
      end

      context 'when no draft exists' do
        subject(:work) { create :work, versions: [v2, v1] }

        its(:draft_version) { is_expected.to be_nil }
      end
    end
  end
end
