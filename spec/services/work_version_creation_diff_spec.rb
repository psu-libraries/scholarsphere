# frozen_string_literal: true

require 'rails_helper'

RSpec.describe WorkVersionCreationDiff do
  subject { described_class.call(base_version, comparison_version) }

  let!(:base_version) { create(:work_version, :with_creators, creator_count: 2) }

  let!(:comparison_version) do
    BuildNewWorkVersion.call(base_version).tap(&:save)
  end

  context 'when a creator-alias has been renamed' do
    let(:original_second_creator) { base_version.creator_aliases[1] }
    let(:updated_second_creator) { comparison_version.creator_aliases[1] }

    before do
      original_second_creator.update(alias: 'Renamed')
    end

    it { is_expected.to eq(renamed: [[original_second_creator, updated_second_creator]], added: [], deleted: []) }
  end

  context 'when a creator has been added' do
    let(:added_creator) { comparison_version.creator_aliases[2] }

    before do
      comparison_version.creator_aliases << build(:work_version_creation, work_version: nil)
      comparison_version.save
    end

    it { is_expected.to eq(renamed: [], added: [added_creator], deleted: []) }
  end

  context 'when a file has been deleted' do
    let(:deleted_creator) { base_version.creator_aliases[2] }

    before do
      base_version.creator_aliases << build(:work_version_creation, work_version: nil)
      base_version.save
    end

    it { is_expected.to eq(renamed: [], added: [], deleted: [deleted_creator]) }
  end
end
