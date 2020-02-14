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
        metadata: work.metadata.merge(
          work_type: 'dataset',
          visibility: Permissions::Visibility::OPEN,
          creator_aliases_attributes: [
            {
              alias: "#{user.given_name} #{user.surname}",
              creator_attributes: {
                email: user.email,
                given_name: user.given_name,
                surname: user.surname,
                psu_id: user.access_id
              }
            }
          ]
        ),
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

  context 'without a required title' do
    let(:service) do
      described_class.call(metadata: {}, depositor: user.access_id, content: [])
    end

    it 'does NOT save the work' do
      expect { service }.not_to change(Work, :count)
    end

    it 'returns the work with errors' do
      expect(service.errors.full_messages).to contain_exactly("Versions title can't be blank")
    end
  end

  context 'when the work has restricted visbility' do
    let(:work) { build(:work_version, :with_complete_metadata) }
    let(:service) do
      described_class.call(
        metadata: work.metadata.merge(
          work_type: 'dataset',
          visibility: Permissions::Visibility::PRIVATE,
          creator_aliases_attributes: [
            {
              alias: "#{user.given_name} #{user.surname}",
              creator_attributes: {
                email: user.email,
                given_name: user.given_name,
                surname: user.surname,
                psu_id: user.access_id
              }
            }
          ]
        ),
        depositor: user.access_id,
        content: [
          { file: fixture_file_upload(File.join(fixture_path, 'image.png')) }
        ]
      )
    end

    it 'creates a new draft work' do
      expect { service }.to change(Work, :count).by(1)
      new_work = Work.last
      expect(new_work.visibility).to eq(Permissions::Visibility::PRIVATE)
      expect(new_work.edit_users.map(&:uid)).to contain_exactly(user.uid)
      expect(new_work.edit_groups.map(&:name)).to be_empty
      expect(new_work.latest_version).to be_draft
    end
  end
end
