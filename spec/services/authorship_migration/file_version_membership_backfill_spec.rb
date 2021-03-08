# frozen_string_literal: true

require 'rails_helper'

# This spec no longer works, because the incorrect setup has been fixed by this
# commit. If you want to run the spec, check out the previous commit
RSpec.xdescribe AuthorshipMigration::FileVersionMembershipBackfill, type: :model, versioning: true do
  let(:user) { create :user }

  before do
    @work = build(:work, has_draft: false, versions_count: 0)
    @version1 = nil
    @version2 = nil

    PaperTrail.request(whodunnit: user.to_gid) do
      @version1 = build(:work_version,
                        :published,
                        work: nil,
                        file_count: 2,
                        version_number: 1)
      @work.versions << @version1
      @work.save
      @version1.reload

      # Edit the title on the first file
      @fvm1_v1 = @version1.file_version_memberships.first
      @fvm1_v1.update!(title: 'updated-title-v1.png')

      @version2 = BuildNewWorkVersion.call(@version1)
      @version2.save
      @version2.reload

      @fvm1_v2 = @version2.file_version_memberships.find { |fvm| fvm.file_resource_id == @fvm1_v1.file_resource_id }

      @fvm1_v2.update!(title: 'updated-title-v2.png')
    end
  end

  describe '#call' do
    def perform_call
      described_class
        .new(previous_version: @version1, next_version: @version2)
        .call
    end
    it 'sets up a sane test environment' do
      expect(@version1.version_number).to eq 1
      expect(@version2.version_number).to eq 2

      expect(@version1.file_version_memberships.length).to eq 2
      expect(@version2.file_version_memberships.length).to eq 2

      expect(PaperTrail::Version.where(item_type: 'FileVersionMembership').count)
        .to eq 4 # 2 creates, 2 updates

      expect(@fvm1_v2.versions.first.event).not_to eq 'create'
    end

    it 'backfills "create" events into subsequent versions' do
      expect {
        perform_call
      }.to change(PaperTrail::Version, :count).by(2)

      @fvm1_v2.versions.first.tap do |backfilled_creation|
        expect(backfilled_creation.event).to eq 'create'
        expect(backfilled_creation.changed_by_system).to eq true
        expect(backfilled_creation.item_type).to eq 'FileVersionMembership'
        expect(backfilled_creation.item_id).to eq @fvm1_v2.id
        expect(backfilled_creation.whodunnit).to eq user.to_gid.to_s
        expect(backfilled_creation.whodunnit).to eq user.to_gid.to_s
        expect(backfilled_creation.object).to be_nil
        expect(backfilled_creation.object_changes).to eq(
          {
            'id' => [nil, @fvm1_v2.id],
            'title' => [nil, 'updated-title-v1.png'],
            'created_at' => [nil, @version2.created_at.iso8601(3)],
            'updated_at' => [nil, @version2.created_at.iso8601(3)],
            'work_version_id' => [nil, @version2.id],
            'file_resource_id' => [nil, @fvm1_v1.file_resource_id]
          }
        )
      end

      fvm2_v2 = @version2.file_version_memberships.find { |fvm| fvm != @fvm1_v2 }
      fvm2_v1 = @version1.file_version_memberships.find { |fvm| fvm.file_resource_id == fvm2_v2.file_resource_id }

      fvm2_v2.versions.first.tap do |backfilled_creation|
        expect(backfilled_creation.event).to eq 'create'
        expect(backfilled_creation.changed_by_system).to eq true
        expect(backfilled_creation.item_type).to eq 'FileVersionMembership'
        expect(backfilled_creation.item_id).to eq fvm2_v2.id
        expect(backfilled_creation.whodunnit).to eq user.to_gid.to_s
        expect(backfilled_creation.whodunnit).to eq user.to_gid.to_s
        expect(backfilled_creation.object).to be_nil
        expect(backfilled_creation.object_changes).to eq(
          {
            'id' => [nil, fvm2_v2.id],
            'title' => [nil, fvm2_v1.title],
            'created_at' => [nil, @version2.created_at.iso8601(3)],
            'updated_at' => [nil, @version2.created_at.iso8601(3)],
            'work_version_id' => [nil, @version2.id],
            'file_resource_id' => [nil, fvm2_v2.file_resource_id]
          }
        )
      end
    end

    it 'is idempotent' do
      perform_call
      expect { perform_call }.not_to change(PaperTrail::Version, :count)
    end
  end

  describe '.backfill_all_file_version_memberships' do
    before do
      @version3 = BuildNewWorkVersion.call(@version2)
      @version3.save
      @version3.reload

      @work_with_1_version = create(:work, has_draft: false, versions_count: 1)
    end

    it 'backfills only works with multiple versions' do
      allow(described_class).to receive(:new).and_return(instance_spy(described_class))

      described_class.backfill_all_file_version_memberships

      expect(described_class).to have_received(:new).twice

      expect(described_class).to have_received(:new).with(previous_version: @version1, next_version: @version2)
      expect(described_class).to have_received(:new).with(previous_version: @version2, next_version: @version3)
    end
  end
end
