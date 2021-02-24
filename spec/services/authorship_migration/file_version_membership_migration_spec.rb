# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AuthorshipMigration::FileVersionMembershipMigration, type: :model, versioning: true do
  before do
    create(:work, versions_count: 2, has_draft: false)
    allow(AuthorshipMigration::FileVersionMembershipBackfill)
      .to receive(:backfill_all_file_version_memberships)
  end

  describe 'migrate_all_file_version_memberships' do
    it 'backfills and migrates FVMs' do
      described_class.migrate_all_file_version_memberships

      expect(AuthorshipMigration::FileVersionMembershipBackfill)
        .to have_received(:backfill_all_file_version_memberships)

      PaperTrail::Version.where(item_type: 'FileVersionMembership').find_each do |fvm|
        expect(fvm.resource_type).to eq 'WorkVersion'
        expect(fvm.resource_id).to eq fvm.work_version_id
      end
    end
  end
end
