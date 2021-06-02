# frozen_string_literal: true

require 'rails_helper'

RSpec.describe FileVersionMembershipDiff do
  subject { described_class.call(base_version, comparison_version) }

  let!(:base_version) { create(:work_version, :with_files, file_count: 2) }

  let!(:comparison_version) do
    BuildNewWorkVersion.call(base_version).tap(&:save)
  end

  context 'when a file has been renamed' do
    let(:original_second_image) { base_version.file_version_memberships[1] }
    let(:updated_second_image) { comparison_version.file_version_memberships[1] }

    before do
      comparison_version.file_version_memberships.last.update(title: 'z.png')
    end

    it { is_expected.to eq(renamed: [[original_second_image, updated_second_image]], added: [], deleted: []) }
  end

  context 'when a file has been added' do
    let(:added_file) { comparison_version.file_version_memberships[2] }

    before do
      comparison_version.file_resources << build(:file_resource)
      comparison_version.save
    end

    it { is_expected.to eq(renamed: [], added: [added_file], deleted: []) }
  end

  context 'when a file has been deleted' do
    let(:deleted_file) { base_version.file_version_memberships[2] }

    before do
      base_version.file_resources << build(:file_resource)
      base_version.save
    end

    it { is_expected.to eq(renamed: [], added: [], deleted: [deleted_file]) }
  end
end
