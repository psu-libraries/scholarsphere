# frozen_string_literal: true

require 'rails_helper'

RSpec.describe WorkVersionCreation, type: :model do
  describe 'table' do
    it { is_expected.to have_db_column(:work_version_id) }
    it { is_expected.to have_db_column(:creator_id) }
    it { is_expected.to have_db_column(:alias).of_type(:string) }
    it { is_expected.to have_db_column(:created_at).of_type(:datetime) }
    it { is_expected.to have_db_column(:updated_at).of_type(:datetime) }
  end

  describe 'factory' do
    it { is_expected.to have_valid_factory(:work_version_creation) }
  end

  describe 'associations' do
    it { is_expected.to belong_to(:work_version) }
    it { is_expected.to belong_to(:creator) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:alias) }
  end

  describe 'PaperTrail::Versions', versioning: true do
    it { is_expected.to respond_to(:changed_by_system).and respond_to(:changed_by_system=) }
    it { is_expected.to be_versioned }

    context 'when the record is marked as changed by the system' do
      let(:work_version_creation) { create(:work_version_creation, changed_by_system: true) }

      it 'does not write a papertrail version' do
        expect(work_version_creation.reload.versions).to be_empty
      end
    end

    context 'when the record is NOT marked as changed by the system' do
      let(:work_version_creation) { create(:work_version_creation, changed_by_system: false) }

      it "writes a version and stores the WorkVersion's FK into the version metadata" do
        paper_trail_version = work_version_creation.versions.first

        expect(paper_trail_version.work_version_id).to eq(
          work_version_creation.work_version_id
        )
      end
    end
  end
end
