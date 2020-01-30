# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PublishNewWork do
  let(:user) { build(:user) }

  context 'with complete metadata, content, and permissions' do
    let(:work) { build(:work_version, :with_complete_metadata) }
    let(:edit_user) { build(:user) }
    let(:edit_group) { build(:group) }

    let(:service) do
      described_class.call(
        metadata: work.metadata.merge(work_type: 'dataset', visibility: Permissions::Visibility::OPEN),
        depositor: user.access_id,
        content: [
          { file: fixture_file_upload(File.join(fixture_path, 'image.png')) },
          { file: fixture_file_upload(File.join(fixture_path, 'ipsum.pdf')) }
        ],
        permissions: {
          edit_users: [edit_user.access_id],
          edit_groups: [edit_group.name]
        }
      )
    end

    it 'creates a new work' do
      expect { service }.to change(Work, :count).by(1)
      new_work = Work.last
      expect(new_work).to be_open_access
      expect(new_work.edit_users.map(&:uid)).to contain_exactly(user.uid, edit_user.uid)
      expect(new_work.edit_groups.map(&:name)).to contain_exactly(edit_group.name)
      expect(new_work.work_type).to eq('dataset')
      expect(new_work.latest_published_version.metadata).to eq(work.metadata)
      expect(new_work.latest_published_version.file_version_memberships.map(&:title)).to contain_exactly(
        'ipsum.pdf', 'image.png'
      )
    end
  end

  context 'with incomplete metadata' do
    let(:service) do
      described_class.call(metadata: {}, depositor: user.access_id, content: [])
    end

    it 'does NOT save the work' do
      expect { service }.not_to change(Work, :count)
    end

    it 'returns the work with errors' do
      expect(service.errors.full_messages).to include(
        "Versions title can't be blank",
        "Versions file resources can't be blank"
      )
    end
  end
end
