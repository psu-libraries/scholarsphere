# frozen_string_literal: true

require 'rails_helper'

# @note When building the parameters for each test, using HashWithIndifferentAccess mimics the same behaviors as
# ActionController::Parameters which the IngestController would be passing to the service.

RSpec.describe Api::V1::WorkPublisher do
  include ActionDispatch::TestProcess::FixtureFile

  let(:user) { build(:user) }
  let(:work) { build(:work_version, :with_complete_metadata) }
  let(:depositor) { build(:person) }
  let(:mock_client) { instance_spy(PsuIdentity::SearchService::Client) }
  let(:new_work) { publisher.work }
  let(:external_app) { build(:external_app) }

  before do
    allow(PsuIdentity::SearchService::Client).to receive(:new).and_return(mock_client)
    allow(mock_client).to receive(:userid).with(depositor.user_id).and_return(depositor)
  end

  context 'when the depositor is the same as the creator' do
    let(:publisher) do
      described_class.call(
        metadata: HashWithIndifferentAccess.new(work.metadata.merge(
                                                  work_type: 'dataset',
                                                  visibility: Permissions::Visibility::OPEN,
                                                  creators: [
                                                    {
                                                      psu_id: depositor.user_id
                                                    }
                                                  ]
                                                )),
        depositor_access_id: depositor.user_id,
        content: [
          HashWithIndifferentAccess.new(file: fixture_file_upload(File.join(fixture_path, 'image.png'))),
          HashWithIndifferentAccess.new(file: fixture_file_upload(File.join(fixture_path, 'ipsum.pdf')))
        ],
        external_app: external_app
      )
    end

    it 'creates an open access work with a single published version, complete metadata, and content' do
      expect(new_work).to be_open_access
      expect(new_work).not_to be_embargoed
      expect(new_work.versions.count).to eq(1)
      expect(new_work.latest_version).to be_published
      expect(new_work.work_type).to eq('dataset')
      expect(new_work.latest_published_version.metadata).to eq(work.metadata)
      expect(new_work.latest_published_version.file_version_memberships.map(&:title)).to contain_exactly(
        'ipsum.pdf', 'image.png'
      )
    end

    it 'creates a new Actor record for the depositor' do
      expect { new_work }.to change(Actor, :count).by(1)
    end

    it 'does NOT create a User record for the depositor' do
      expect { new_work }.not_to change(User, :count)
    end

    it 'links the created WorkVersion to the given ExternalApp' do
      expect(new_work.latest_version.external_app).to eq external_app
    end
  end

  context 'when the depositor has a different display name' do
    let(:authorship) { attributes_for(:authorship) }
    let(:publisher) do
      described_class.call(
        metadata: HashWithIndifferentAccess.new(work.metadata.merge(
                                                  work_type: 'dataset',
                                                  visibility: Permissions::Visibility::OPEN,
                                                  creators: [
                                                    {
                                                      psu_id: depositor.user_id,
                                                      display_name: authorship[:display_name]
                                                    }
                                                  ]
                                                )),
        depositor_access_id: depositor.user_id,
        content: [
          HashWithIndifferentAccess.new(file: fixture_file_upload(File.join(fixture_path, 'image.png'))),
          HashWithIndifferentAccess.new(file: fixture_file_upload(File.join(fixture_path, 'ipsum.pdf')))
        ]
      )
    end

    it 'publishes the work using the specified display name' do
      expect(new_work.latest_published_version.creators.first.display_name).to eq(authorship[:display_name])
    end

    it 'creates a new Actor record for the depositor WITHOUT using the specified display name' do
      expect { new_work }.to change(Actor, :count).by(1)
      expect(new_work.latest_published_version.creators.first.actor.display_name).not_to eq(authorship[:display_name])
    end

    it 'does NOT create a User record for the depositor' do
      expect { new_work }.not_to change(User, :count)
    end
  end

  context 'when the actor already exists in the system' do
    let(:publisher) do
      described_class.call(
        metadata: HashWithIndifferentAccess.new(work.metadata.merge(
                                                  work_type: 'dataset',
                                                  visibility: Permissions::Visibility::OPEN,
                                                  creators: [
                                                    {
                                                      psu_id: depositor.user_id
                                                    }
                                                  ]
                                                )),
        depositor_access_id: depositor.user_id,
        content: [
          HashWithIndifferentAccess.new(file: fixture_file_upload(File.join(fixture_path, 'image.png')))
        ]
      )
    end

    before { create(:actor, psu_id: depositor.user_id) }

    it 'creates a new work' do
      expect { new_work }.to change(Work, :count).by(1)
    end

    it 'does not create an Actor record for the depositor' do
      expect { new_work }.not_to change(Actor, :count)
    end

    it 'does NOT create a User record for the depositor' do
      expect { new_work }.not_to change(User, :count)
    end
  end

  context 'when adding mulitple unidentified creators' do
    let(:first_creator) { attributes_for(:authorship) }
    let(:second_creator) { attributes_for(:authorship) }
    let(:third_creator) { attributes_for(:authorship) }
    let(:creators) { new_work.latest_version.creators }

    let(:publisher) do
      described_class.call(
        metadata: HashWithIndifferentAccess.new(work.metadata.merge(
                                                  work_type: 'dataset',
                                                  visibility: Permissions::Visibility::OPEN,
                                                  creators: [
                                                    first_creator,
                                                    second_creator,
                                                    third_creator
                                                  ]
                                                )),
        depositor_access_id: depositor.user_id,
        content: [
          HashWithIndifferentAccess.new(file: fixture_file_upload(File.join(fixture_path, 'image.png')))
        ]
      )
    end

    before { create(:actor, psu_id: depositor.user_id) }

    it 'creates a new work with the creators in the submitted order' do
      expect { new_work }.to change(Work, :count).by(1)
      expect(creators[0].display_name).to eq(first_creator[:display_name])
      expect(creators[0].position).to eq(10)
      expect(creators[1].display_name).to eq(second_creator[:display_name])
      expect(creators[1].position).to eq(20)
      expect(creators[2].display_name).to eq(third_creator[:display_name])
      expect(creators[2].position).to eq(30)
    end

    it 'does not create any Actor records' do
      expect { new_work }.not_to change(Actor, :count)
    end

    it 'does NOT create any User records' do
      expect { new_work }.not_to change(User, :count)
    end
  end

  context 'when specifying additional permissions on the work' do
    let(:edit_user) { build(:person) }
    let(:edit_group) { build(:group) }
    let(:publisher) do
      described_class.call(
        metadata: HashWithIndifferentAccess.new(work.metadata.merge(
                                                  work_type: 'dataset',
                                                  visibility: Permissions::Visibility::OPEN,
                                                  creators: [
                                                    {
                                                      psu_id: depositor.user_id
                                                    }
                                                  ]
                                                )),
        depositor_access_id: depositor.user_id,
        content: [
          HashWithIndifferentAccess.new(file: fixture_file_upload(File.join(fixture_path, 'image.png')))
        ],
        permissions: {
          edit_users: [edit_user.user_id],
          edit_groups: [edit_group.name]
        }
      )
    end

    # @note Save specific groups and users prior to the test so our expectations reflect the changes that the service
    # is making, as opposed to the additional changes due to an empty database.
    before do
      allow(mock_client).to receive(:userid).with(edit_user.user_id).and_return(edit_user)
      create(:actor, psu_id: depositor.user_id)
      Group.public_agent
      Group.authorized_agent
    end

    it 'creates a new Group record for the edit group in the permissions parameter' do
      expect { new_work }.to change(Group, :count).from(2).to(3)
    end

    it 'creates a new User record for the edit user in the permissions parameter' do
      expect { new_work }.to change(User, :count).from(0).to(1)
    end

    it 'creates a new Actor record for the edit user in the permissions parameter' do
      expect { new_work }.to change(Actor, :count).from(1).to(2)
    end

    it 'adds access controls for the two additional permissions as well as public visibility' do
      expect { new_work }.to change(AccessControl, :count).from(0).to(8)
    end
  end

  context 'without all the required metadata' do
    let(:publisher) do
      described_class.call(metadata: {}, depositor_access_id: depositor.user_id, content: [])
    end

    it 'does NOT save the work' do
      expect { new_work }.not_to change(Work, :count)
    end

    it 'does NOT create an Actor for the depositor' do
      expect { new_work }.not_to change(Actor, :count)
    end

    it 'does NOT create a User record for the depositor' do
      expect { new_work }.not_to change(User, :count)
    end

    it 'returns the work with errors' do
      expect(new_work.errors.full_messages).to contain_exactly(
        "Versions title can't be blank",
        'Versions description is required to publish the work',
        "Versions creators can't be blank",
        "Versions file resources can't be blank",
        'Versions published date is not a valid date in EDTF format',
        'Versions published date is required to publish the work',
        'Versions visibility cannot be private',
        "Work type can't be blank",
        'Versions rights is required to publish the work'
      )
    end
  end

  context 'when the work has restricted visbility' do
    let(:publisher) do
      described_class.call(
        metadata: HashWithIndifferentAccess.new(work.metadata.merge(
                                                  work_type: 'dataset',
                                                  visibility: Permissions::Visibility::PRIVATE,
                                                  creators: [
                                                    {
                                                      psu_id: depositor.user_id
                                                    }
                                                  ]
                                                )),
        depositor_access_id: depositor.user_id,
        content: [
          HashWithIndifferentAccess.new(file: fixture_file_upload(File.join(fixture_path, 'image.png')))
        ]
      )
    end

    it 'does NOT save the work' do
      expect { new_work }.not_to change(Work, :count)
    end

    it 'does NOT create an Actor for the depositor' do
      expect { new_work }.not_to change(Actor, :count)
    end

    it 'does NOT create a User record for the depositor' do
      expect { new_work }.not_to change(User, :count)
    end

    it 'returns the work with errors' do
      expect(new_work.errors.full_messages).to contain_exactly('Versions visibility cannot be private')
    end
  end

  context 'when the work is embargoed' do
    let(:publisher) do
      described_class.call(
        metadata: HashWithIndifferentAccess.new(work.metadata.merge(
                                                  work_type: 'dataset',
                                                  visibility: Permissions::Visibility::OPEN,
                                                  creators: [
                                                    {
                                                      psu_id: depositor.user_id
                                                    }
                                                  ],
                                                  embargoed_until: (Time.zone.now + 2.months)
                                                )),
        depositor_access_id: depositor.user_id,
        content: [
          HashWithIndifferentAccess.new(file: fixture_file_upload(File.join(fixture_path, 'image.png')))
        ]
      )
    end

    it 'creates an open access, embargoed work with a single published version, complete metadata, and content' do
      expect(new_work).to be_open_access
      expect(new_work).to be_embargoed
      expect(new_work.versions.count).to eq(1)
      expect(new_work.latest_version).to be_published
      expect(new_work.work_type).to eq('dataset')
      expect(new_work.latest_published_version.metadata).to eq(work.metadata)
      expect(new_work.latest_published_version.file_version_memberships.map(&:title)).to contain_exactly('image.png')
    end
  end

  context 'with custom deposit dates' do
    let(:publisher) do
      described_class.call(
        metadata: HashWithIndifferentAccess.new(work.metadata.merge(
                                                  work_type: 'dataset',
                                                  visibility: Permissions::Visibility::OPEN,
                                                  creators: [
                                                    {
                                                      psu_id: depositor.user_id
                                                    }
                                                  ],
                                                  deposited_at: '2018-02-28T15:12:54Z'
                                                )),
        depositor_access_id: depositor.user_id,
        content: [
          HashWithIndifferentAccess.new(
            file: fixture_file_upload(File.join(fixture_path, 'image.png')),
            deposited_at: '2018-03-01T10:13:00Z'
          )
        ]
      )
    end

    it 'creates a work using the specified deposit dates' do
      expect(new_work).to be_open_access
      expect(new_work.deposited_at.strftime('%Y-%m-%d')).to eq('2018-02-28')
      expect(new_work.deposited_at).to be_a(ActiveSupport::TimeWithZone)
      expect(new_work.deposited_at.zone).to eq('EST')
      expect(new_work.versions.count).to eq(1)
      expect(new_work.latest_version).to be_published
      expect(new_work.work_type).to eq('dataset')
      expect(new_work.latest_published_version.metadata).to eq(work.metadata)
      expect(new_work.latest_published_version.file_version_memberships.map(&:title)).to contain_exactly('image.png')
      expect(new_work.latest_published_version.file_resources.first.deposited_at.strftime('%Y-%m-%d')).to eq(
        '2018-03-01'
      )
    end
  end

  context 'without a work type' do
    let(:publisher) do
      described_class.call(
        metadata: HashWithIndifferentAccess.new(work.metadata.merge(
                                                  work_type: '',
                                                  creators: [
                                                    {
                                                      psu_id: depositor.user_id
                                                    }
                                                  ]
                                                )),
        depositor_access_id: depositor.user_id,
        content: [
          HashWithIndifferentAccess.new(file: fixture_file_upload(File.join(fixture_path, 'image.png')))
        ]
      )
    end

    it 'does NOT save the work' do
      expect { new_work }.not_to change(Work, :count)
    end

    it 'returns the work with errors' do
      expect(new_work.errors.full_messages).to include(
        "Work type can't be blank"
      )
    end
  end

  context 'when a given ids do not exist' do
    let(:publisher) do
      described_class.call(
        metadata: HashWithIndifferentAccess.new(work.metadata.merge(
                                                  work_type: 'dataset',
                                                  visibility: Permissions::Visibility::OPEN,
                                                  creators: [
                                                    { orcid: 'missing-orcid' },
                                                    { psu_id: depositor.user_id },
                                                    { psu_id: 'missing-id' }
                                                  ]
                                                )),
        depositor_access_id: depositor.user_id,
        content: [
          HashWithIndifferentAccess.new(file: fixture_file_upload(File.join(fixture_path, 'image.png'))),
          HashWithIndifferentAccess.new(file: fixture_file_upload(File.join(fixture_path, 'ipsum.pdf')))
        ]
      )
    end

    before do
      allow(mock_client).to receive(:userid).with('missing-id').and_raise(PsuIdentity::SearchService::NotFound)
      allow(Orcid::Public).to receive(:get).with(action: 'person', id: 'missingorcid').and_raise(Orcid::NotFound)
    end

    it 'does NOT save the work' do
      expect { publisher }.not_to change(Work, :count)
    end

    it 'retains all the creators and returns the work with errors' do
      expect(new_work.versions.first.creators.length).to eq(3)
      expect(publisher.errors.full_messages).to include(
        'Psu access id missing-id was not found at Penn State',
        'Orcid id missing-orcid was not found in ORCiD'
      )
    end
  end

  context 'when the depositor does not exist' do
    let(:creator) { build(:person) }

    let(:publisher) do
      described_class.call(
        metadata: HashWithIndifferentAccess.new(work.metadata.merge(
                                                  work_type: 'dataset',
                                                  visibility: Permissions::Visibility::OPEN,
                                                  creators: [
                                                    { psu_id: creator.user_id }
                                                  ]
                                                )),
        depositor_access_id: 'missing-id',
        content: [
          HashWithIndifferentAccess.new(file: fixture_file_upload(File.join(fixture_path, 'image.png'))),
          HashWithIndifferentAccess.new(file: fixture_file_upload(File.join(fixture_path, 'ipsum.pdf')))
        ]
      )
    end

    before do
      allow(mock_client).to receive(:userid).with(creator.user_id).and_return(creator)
      allow(mock_client).to receive(:userid).with('missing-id').and_raise(PsuIdentity::SearchService::NotFound)
    end

    it 'raises an error' do
      expect { publisher }.to raise_error(PsuIdentity::SearchService::NotFound)
    end
  end
end
