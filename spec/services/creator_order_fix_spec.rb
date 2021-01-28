# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CreatorOrderFix, versioning: true do
  context 'when everything is hunky-dory' do
    let(:work) do
      first_version = create(:work_version, :published, creator_count: 3)
      work = first_version.work
      work.versions[0].destroy # this is a bug with the factory builder
      work.reload
      new_version = BuildNewWorkVersion.call(work.latest_version)
      new_version.save
      work.reload
      work
    end

    it 'does not change the positions' do
      expect(work.versions[0].creator_aliases[0].position).to eq(1)
      expect(work.versions[0].creator_aliases[1].position).to eq(2)
      expect(work.versions[0].creator_aliases[2].position).to eq(3)
      expect(work.versions[1].creator_aliases[0].position).to eq(1)
      expect(work.versions[1].creator_aliases[1].position).to eq(2)
      expect(work.versions[1].creator_aliases[2].position).to eq(3)

      expect {
        described_class.call
      }.not_to change(PaperTrail::Version, :count)

      work.reload
      expect(work.versions[0].creator_aliases[0].position).to eq(1)
      expect(work.versions[0].creator_aliases[1].position).to eq(2)
      expect(work.versions[0].creator_aliases[2].position).to eq(3)
      expect(work.versions[1].creator_aliases[0].position).to eq(1)
      expect(work.versions[1].creator_aliases[1].position).to eq(2)
      expect(work.versions[1].creator_aliases[2].position).to eq(3)
    end
  end

  # Use case: User creates a new version of an existing published work and the positions is NOT copied over to the new
  # version. This was the bug that Ryan fixed recently, but we must account for works that had new versions added prior
  # to the fix.
  context 'with three creators and three versions' do
    let(:work) do
      first_version = create(:work_version, :published, creator_count: 3)
      work = first_version.work
      work.versions[0].destroy # this is a bug with the factory builder
      work.reload
      second_version = BuildNewWorkVersion.call(work.latest_version)
      second_version.save
      third_version = BuildNewWorkVersion.call(second_version)
      third_version.save
      work.reload
      work.versions[1].creator_aliases.map do |creator_alias|
        creator_alias.update(position: nil)
      end
      work.versions[2].creator_aliases.map do |creator_alias|
        creator_alias.update(position: nil)
      end
      work.reload
    end

    it 'updates the null positions' do
      expect(work.versions[0].creator_aliases[0].position).to eq(1)
      expect(work.versions[0].creator_aliases[1].position).to eq(2)
      expect(work.versions[0].creator_aliases[2].position).to eq(3)
      expect(work.versions[1].creator_aliases[0].position).to eq(nil)
      expect(work.versions[1].creator_aliases[1].position).to eq(nil)
      expect(work.versions[1].creator_aliases[2].position).to eq(nil)
      expect(work.versions[2].creator_aliases[0].position).to eq(nil)
      expect(work.versions[2].creator_aliases[1].position).to eq(nil)
      expect(work.versions[2].creator_aliases[2].position).to eq(nil)

      expect {
        described_class.call
      }.not_to change(PaperTrail::Version, :count)

      work.reload
      expect(work.versions[0].creator_aliases[0].position).to eq(1)
      expect(work.versions[0].creator_aliases[1].position).to eq(2)
      expect(work.versions[0].creator_aliases[2].position).to eq(3)
      expect(work.versions[1].creator_aliases[0].position).to eq(1)
      expect(work.versions[1].creator_aliases[1].position).to eq(2)
      expect(work.versions[1].creator_aliases[2].position).to eq(3)
      expect(work.versions[2].creator_aliases[0].position).to eq(1)
      expect(work.versions[2].creator_aliases[1].position).to eq(2)
      expect(work.versions[2].creator_aliases[2].position).to eq(3)
    end
  end

  # Use case: A work was migrated with all of its initial creator positions set to nil.
  context 'with a migrated work' do
    let(:work) do
      first_version = create(:work_version, :published, creator_count: 3)
      work = first_version.work
      work.versions[0].destroy # this is a bug with the factory builder
      work.reload
      work.versions[0].creator_aliases.map do |creator_alias|
        creator_alias.update(position: nil)
      end
      work.reload
    end

    # Note: positions here are in increments of 10 because that's what the UI does
    it 'updates the null positions' do
      expect(work.versions[0].creator_aliases[0].position).to eq(nil)
      expect(work.versions[0].creator_aliases[1].position).to eq(nil)
      expect(work.versions[0].creator_aliases[2].position).to eq(nil)

      expect {
        described_class.call
      }.not_to change(PaperTrail::Version, :count)

      work.reload
      expect(work.versions[0].creator_aliases[0].position).to eq(10)
      expect(work.versions[0].creator_aliases[1].position).to eq(20)
      expect(work.versions[0].creator_aliases[2].position).to eq(30)
    end
  end

  context 'when something is very wrong' do
    let(:work) do
      first_version = create(:work_version, :published, creator_count: 3)
      work = first_version.work
      work.versions[0].destroy # this is a bug with the factory builder
      work.reload
      work.versions[0].creator_aliases[1].update(position: nil)
      work.reload
    end

    it 'returns false and puts errors to stdout' do
      expect(work.versions[0].creator_aliases[0].position).to eq(1)
      expect(work.versions[0].creator_aliases[1].position).to eq(3)
      expect(work.versions[0].creator_aliases[2].position).to eq(nil)

      expected_output = /Work##{work.id}, WorkVersion##{work.versions[0].id}, Work #{work.uuid} can't be corrected/

      return_value = nil
      expect { return_value = described_class.call }.to output(expected_output).to_stdout
      expect(return_value).to eq false
    end
  end
end
