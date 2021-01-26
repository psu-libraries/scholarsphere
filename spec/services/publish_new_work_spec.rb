# frozen_string_literal: true

require 'rails_helper'

# @note This is the main service that migrates existing Scholarsphere 3 works into the application via the
# IngestController. There are several examples that represent typical Scholarsphere 3 works, as well as some of the more
# outlying complex works, with multiple creators, different permissions, and proxy depositors.

# @note When building the parameters for each test, using HashWithIndifferentAccess mimics the same behaviors as
# ActionController::Parameters which the IngestController would be passing to the service.

RSpec.describe PublishNewWork do
  let(:user) { build(:user) }
  let(:work) { build(:work_version, :with_complete_metadata) }

  let(:depositor) do
    HashWithIndifferentAccess.new(
      email: user.email,
      given_name: user.actor.given_name,
      surname: user.actor.surname,
      psu_id: user.actor.psu_id
    )
  end

  context 'when the depositor is the same as the creator' do
    let(:new_work) do
      described_class.call(
        metadata: HashWithIndifferentAccess.new(work.metadata.merge(
                                                  work_type: 'dataset',
                                                  creators_attributes: [
                                                    {
                                                      alias: user.name,
                                                      actor_attributes: {
                                                        email: user.email,
                                                        given_name: user.actor.given_name,
                                                        surname: user.actor.surname,
                                                        psu_id: user.actor.psu_id
                                                      }
                                                    }
                                                  ]
                                                )),
        depositor: depositor,
        content: [
          HashWithIndifferentAccess.new(file: fixture_file_upload(File.join(fixture_path, 'image.png'))),
          HashWithIndifferentAccess.new(file: fixture_file_upload(File.join(fixture_path, 'ipsum.pdf')))
        ]
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
  end

  context 'when the actor already exists in the system' do
    let(:new_work) do
      described_class.call(
        metadata: HashWithIndifferentAccess.new(work.metadata.merge(
                                                  work_type: 'dataset',
                                                  creators_attributes: [
                                                    {
                                                      alias: user.name,
                                                      actor_attributes: {
                                                        email: user.email,
                                                        given_name: user.actor.given_name,
                                                        surname: user.actor.surname,
                                                        psu_id: user.actor.psu_id
                                                      }
                                                    }
                                                  ]
                                                )),
        depositor: depositor,
        content: [
          HashWithIndifferentAccess.new(file: fixture_file_upload(File.join(fixture_path, 'image.png')))
        ]
      )
    end

    before { user.save }

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

  context 'when specifying additional permissions on the work' do
    let(:edit_user) { build(:person) }
    let(:edit_group) { build(:group) }
    let(:mock_client) { instance_spy('PennState::SearchService::Client') }
    let(:new_work) do
      described_class.call(
        metadata: HashWithIndifferentAccess.new(work.metadata.merge(
                                                  work_type: 'dataset',
                                                  creators_attributes: [
                                                    {
                                                      alias: user.name,
                                                      actor_attributes: {
                                                        email: user.email,
                                                        given_name: user.actor.given_name,
                                                        surname: user.actor.surname,
                                                        psu_id: user.actor.psu_id
                                                      }
                                                    }
                                                  ]
                                                )),
        depositor: depositor,
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
      allow(PennState::SearchService::Client).to receive(:new).and_return(mock_client)
      allow(mock_client).to receive(:userid).with(edit_user.user_id).and_return(edit_user)
      user.save
      Group.public_agent
      Group.authorized_agent
    end

    it 'creates a new Group record for the edit group in the permissions parameter' do
      expect { new_work }.to change(Group, :count).from(2).to(3)
    end

    it 'creates a new User record for the edit user in the permissions parameter' do
      expect { new_work }.to change(User, :count).from(1).to(2)
    end

    it 'creates a new Actor record for the edit user in the permissions parameter' do
      expect { new_work }.to change(Actor, :count).from(1).to(2)
    end

    it 'adds access controls for the two additional permissions as well as public visibility' do
      expect { new_work }.to change(AccessControl, :count).from(0).to(8)
    end
  end

  context 'without a required title' do
    let(:new_work) do
      described_class.call(metadata: {}, depositor: depositor, content: [])
    end

    it 'does NOT save the work' do
      expect { new_work }.not_to change(Work, :count)
    end

    it 'does NOT create an Actor for the depositor' do
      pending('Need to implement transactions to rollback any changes to the database when works fail to save')
      expect { new_work }.not_to change(Actor, :count).by(1)
    end

    it 'does NOT create a User record for the depositor' do
      expect { new_work }.not_to change(User, :count)
    end

    it 'returns the work with errors' do
      expect(new_work.errors.full_messages).to contain_exactly("Versions title can't be blank")
    end
  end

  context "when the collection has attributes that wouldn't pass validation outside of a migration" do
    let(:new_work) do
      described_class.call(
        metadata: HashWithIndifferentAccess.new(work.metadata.merge(
                                                  work_type: 'dataset',
                                                  published_date: 'not a valid EDTF date',
                                                  creators_attributes: [
                                                    {
                                                      alias: user.name,
                                                      actor_attributes: {
                                                        email: user.email,
                                                        given_name: user.actor.given_name,
                                                        surname: user.actor.surname,
                                                        psu_id: user.actor.psu_id
                                                      }
                                                    }
                                                  ]
                                                )),
        depositor: depositor,
        content: [
          HashWithIndifferentAccess.new(file: fixture_file_upload(File.join(fixture_path, 'image.png'))),
          HashWithIndifferentAccess.new(file: fixture_file_upload(File.join(fixture_path, 'ipsum.pdf')))
        ]
      )
    end

    it 'saves the work' do
      expect(new_work).to be_persisted
      expect(new_work.versions.count).to eq(1)
      expect(new_work.latest_version).to be_persisted.and be_published
    end
  end

  context 'when the work has restricted visbility' do
    let(:new_work) do
      described_class.call(
        metadata: HashWithIndifferentAccess.new(work.metadata.merge(
                                                  work_type: 'dataset',
                                                  visibility: Permissions::Visibility::PRIVATE,
                                                  creators_attributes: [
                                                    {
                                                      alias: user.name,
                                                      actor_attributes: {
                                                        email: user.email,
                                                        given_name: user.actor.given_name,
                                                        surname: user.actor.surname,
                                                        psu_id: user.actor.psu_id
                                                      }
                                                    }
                                                  ]
                                                )),
        depositor: depositor,
        content: [
          HashWithIndifferentAccess.new(file: fixture_file_upload(File.join(fixture_path, 'image.png')))
        ]
      )
    end

    it 'creates an private work with a single DRAFT version, complete metadata, and content' do
      expect(new_work).not_to be_open_access
      expect(new_work).not_to be_authorized_access
      expect(new_work).not_to be_embargoed
      expect(new_work.visibility).to eq(Permissions::Visibility::PRIVATE)
      expect(new_work.work_type).to eq('dataset')
      expect(new_work.versions.count).to eq(1)
      expect(new_work.latest_version).to be_persisted
      expect(new_work.latest_version).to be_draft
      expect(new_work.latest_version.metadata).to eq(work.metadata)
      expect(new_work.latest_version.file_version_memberships.map(&:title)).to contain_exactly('image.png')
    end

    it 'creates a new Actor record for the depositor' do
      expect { new_work }.to change(Actor, :count).by(1)
    end

    it 'does NOT create a User record for the depositor' do
      expect { new_work }.not_to change(User, :count)
    end
  end

  context 'when the work has a NOID from Scholarpshere 3' do
    let(:noid) { FactoryBotHelpers.noid }

    let(:new_work) do
      described_class.call(
        metadata: HashWithIndifferentAccess.new(work.metadata.merge(
                                                  work_type: 'dataset',
                                                  creators_attributes: [
                                                    {
                                                      alias: user.name,
                                                      actor_attributes: {
                                                        email: user.email,
                                                        given_name: user.actor.given_name,
                                                        surname: user.actor.surname,
                                                        psu_id: user.actor.psu_id
                                                      }
                                                    }
                                                  ],
                                                  noid: noid
                                                )),
        depositor: depositor,
        content: [
          HashWithIndifferentAccess.new(file: fixture_file_upload(File.join(fixture_path, 'image.png')))
        ]
      )
    end

    it 'creates a new work with a legacy identifier' do
      expect {
        new_work
      }.to change {
        LegacyIdentifier.find_by(old_id: noid, resource_type: 'Work')
      }.from(nil).to(a_kind_of(LegacyIdentifier))
    end
  end

  context 'when the work is embargoed' do
    let(:new_work) do
      described_class.call(
        metadata: HashWithIndifferentAccess.new(work.metadata.merge(
                                                  work_type: 'dataset',
                                                  creators_attributes: [
                                                    {
                                                      alias: user.name,
                                                      actor_attributes: {
                                                        email: user.email,
                                                        given_name: user.actor.given_name,
                                                        surname: user.actor.surname,
                                                        psu_id: user.actor.psu_id
                                                      }
                                                    }
                                                  ],
                                                  embargoed_until: (Time.zone.now + 2.months)
                                                )),
        depositor: depositor,
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
    let(:new_work) do
      described_class.call(
        metadata: HashWithIndifferentAccess.new(work.metadata.merge(
                                                  work_type: 'dataset',
                                                  creators_attributes: [
                                                    {
                                                      alias: user.name,
                                                      actor_attributes: {
                                                        email: user.email,
                                                        given_name: user.actor.given_name,
                                                        surname: user.actor.surname,
                                                        psu_id: user.actor.psu_id
                                                      }
                                                    }
                                                  ],
                                                  deposited_at: '2018-02-28T15:12:54Z'
                                                )),
        depositor: depositor,
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

  context 'when the file has a NOID from Scholarsphere 3' do
    let(:noid) { FactoryBotHelpers.noid }

    let(:new_work) do
      described_class.call(
        metadata: HashWithIndifferentAccess.new(work.metadata.merge(
                                                  work_type: 'dataset',
                                                  creators_attributes: [
                                                    {
                                                      alias: user.name,
                                                      actor_attributes: {
                                                        email: user.email,
                                                        given_name: user.actor.given_name,
                                                        surname: user.actor.surname,
                                                        psu_id: user.actor.psu_id
                                                      }
                                                    }
                                                  ],
                                                  deposited_at: '2018-02-28T15:12:54Z'
                                                )),
        depositor: depositor,
        content: [
          HashWithIndifferentAccess.new(
            file: fixture_file_upload(File.join(fixture_path, 'image.png')),
            noid: noid
          )
        ]
      )
    end

    it 'creates a file with the legacy identifier' do
      expect {
        new_work
      }.to change {
        LegacyIdentifier.find_by(old_id: noid, resource_type: 'FileResource')
      }.from(nil).to(a_kind_of(LegacyIdentifier))
    end
  end

  context 'without a work type' do
    let(:new_work) do
      described_class.call(
        metadata: HashWithIndifferentAccess.new(work.metadata.merge(
                                                  work_type: '',
                                                  creators_attributes: [
                                                    {
                                                      alias: user.name,
                                                      actor_attributes: {
                                                        email: user.email,
                                                        given_name: user.actor.given_name,
                                                        surname: user.actor.surname,
                                                        psu_id: user.actor.psu_id
                                                      }
                                                    }
                                                  ]
                                                )),
        depositor: depositor,
        content: [
          HashWithIndifferentAccess.new(file: fixture_file_upload(File.join(fixture_path, 'image.png')))
        ]
      )
    end

    it 'creates a work using the specified deposit dates' do
      expect(new_work.latest_version).to be_published
      expect(new_work.work_type).to eq(Work::Types.unspecified)
    end
  end
end
