# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AuthorshipMigration::WorkVersionCreationMigration, type: :model, versioning: true do
  let(:user) { create :user }
  let(:work_version) { create :work_version }

  before do
    # We will create three WorkVerisonCreations, one of which will be deleted.
    # We also need some Actors to be associated with them.
    @act1 = create(:actor, psu_id: 'act001', given_name: 'Actor1')
    @act2 = create(:actor, psu_id: 'act002', given_name: 'Actor2')
    @act_deleted = create(:actor, psu_id: 'act000', given_name: 'ActorDeleted')

    @wvc1 = nil
    @wvc2 = nil
    @wvc_deleted = nil

    PaperTrail.request(whodunnit: user.to_gid) do
      Timecop.freeze(Time.zone.local(2021, 1, 1)) do
        @wvc1 = create(
          :work_version_creation,
          work_version: work_version,
          actor: @act1,
          alias: 'Original Alias for Actor 1',
          position: 10
        )
      end

      Timecop.freeze(Time.zone.local(2021, 1, 2)) do
        @wvc1.update(alias: 'New Alias for Actor 1')
      end

      Timecop.freeze(Time.zone.local(2021, 1, 3)) do
        @wvc1.update(position: 20)

        @wvc2 = create(
          :work_version_creation,
          work_version: work_version,
          actor: @act2,
          alias: 'Original Alias for Actor 2',
          position: 10
        )
      end

      Timecop.freeze(Time.zone.local(2021, 1, 4)) do
        @wvc_deleted = create(
          :work_version_creation,
          work_version: work_version,
          actor: @act_deleted,
          alias: 'Original Alias for Actor Deleted',
          position: 10
        )
      end

      Timecop.freeze(Time.zone.local(2021, 1, 5)) do
        @wvc_deleted.destroy
      end
    end
  end

  describe '.call' do
    def perform_call
      described_class.call(work_version: work_version)
    end

    # Sanity checks
    it 'sets up a sane test environment' do
      expect(PaperTrail::Version.where(item_type: 'WorkVersionCreation').count)
        .to eq 6

      expect(@wvc1.versions.map { |v| v.created_at.to_date })
        .to match_array([
                          Time.zone.local(2021, 1, 1).to_date,
                          Time.zone.local(2021, 1, 2).to_date,
                          Time.zone.local(2021, 1, 3).to_date
                        ])
    end

    context 'when on the happy path' do
      it 'creates a corresponding number of Authorship records' do
        expect { perform_call }
          .to change(Authorship, :count)
          .by(2) # Note, TWO, because one of the WVC's above is deleted
      end

      it 'recreates the editing history of the migrated WorkVersionCreations' do
        perform_call
        expect(PaperTrail::Version.where(item_type: 'WorkVersionCreation').count)
          .to eq(PaperTrail::Version.where(item_type: 'Authorship').count)

        authorship1 = Authorship.find_by(actor_id: @act1)
        expect(authorship1.resource).to eq work_version
        expect(authorship1.alias).to eq 'New Alias for Actor 1'
        expect(authorship1.given_name).to eq @act1.given_name
        expect(authorship1.surname).to eq @act1.surname
        expect(authorship1.email).to eq @act1.email
        expect(authorship1.position).to eq 20
        expect(authorship1.actor_id).to eq @act1.id
        expect(authorship1.instance_token).to be_present
        expect(authorship1.created_at.to_date).to eq Time.zone.local(2021, 1, 1).to_date
        expect(authorship1.updated_at.to_date).to eq Time.zone.local(2021, 1, 3).to_date

        expect(authorship1.versions.length).to eq 3
        v1, v2, v3 = authorship1.versions
        expect(v1.whodunnit).to eq user.to_gid.to_s
        expect(v1.event).to eq 'create'
        expect(v1.changeset[:display_name]).to eq @wvc1.versions[0].changeset[:alias]
        expect(v1.changeset[:actor_id]).to eq @wvc1.versions[0].changeset[:actor_id]
        expect(v1.changeset[:position]).to eq @wvc1.versions[0].changeset[:position]
        expect(v1.changeset[:created_at]).to eq @wvc1.versions[0].changeset[:created_at]
        expect(v1.changeset[:updated_at]).to eq @wvc1.versions[0].changeset[:updated_at]
        expect(v1.created_at.to_date).to eq Time.zone.local(2021, 1, 1).to_date

        expect(v2.event).to eq 'update'
        expect(v2.changeset[:display_name]).to eq(@wvc1.versions[1].changeset[:alias])
        expect(v2.changeset[:created_at]).to eq(@wvc1.versions[1].changeset[:created_at])
        expect(v2.changeset[:updated_at]).to eq(@wvc1.versions[1].changeset[:updated_at])
        expect(v2.created_at.to_date).to eq Time.zone.local(2021, 1, 2).to_date

        expect(v3.event).to eq 'update'
        expect(v3.changeset).to eq(@wvc1.versions[2].changeset)
        expect(v3.created_at.to_date).to eq Time.zone.local(2021, 1, 3).to_date

        authorship2 = Authorship.find_by(actor_id: @act2)
        expect(authorship2.versions.length).to eq 1

        # Test deleted actor, have to extract from DB.
        expect(Authorship.find_by(actor_id: @act_deleted)).to be_nil
        deleted_v1 = PaperTrail::Version
          .where(item_type: 'Authorship', event: 'create')
          .where_object_changes(actor_id: @act_deleted.id)
          .first
        expect(deleted_v1.created_at.to_date).to eq Time.zone.local(2021, 1, 4).to_date
        expect(deleted_v1.changeset[:display_name].last).to eq 'Original Alias for Actor Deleted'

        deleted_v2 = deleted_v1.next
        expect(deleted_v2.event).to eq 'destroy'
      end

      it 'is idempotent' do
        perform_call
        expect { perform_call }.not_to change(Authorship, :count)
        expect { perform_call }.not_to change(PaperTrail::Version, :count)
      end
    end

    context 'when an actor is missing' do
      before { [@wvc1, @act1].each(&:destroy) }

      it 'reports the error, continues to migrate the rest of the creators' do
        authorship_count_before = Authorship.count
        versions_count_before = PaperTrail::Version.count

        errors = perform_call

        expect(errors.length).to eq 1
        expect(errors.first).to match(/WorkVersion##{work_version.id}/i)
          .and match(/could not find Actor##{@act1.id}/i)

        # It skips the first creator because it errors out, but continues to
        # migrate the other two (one of which is deleted)
        expect(Authorship.count - authorship_count_before).to eq 1
        expect(PaperTrail::Version.count - versions_count_before).to eq 3
      end
    end

    context 'when the paper trail version describing the _create_ is missing' do
      before do
        @wvc1.versions.first.destroy!
      end

      it 'still works' do
        authorship_count_before = Authorship.count
        versions_count_before = PaperTrail::Version.count

        errors = perform_call

        expect(errors).to be_empty

        expect(Authorship.count - authorship_count_before).to eq 2
        expect(PaperTrail::Version.count - versions_count_before).to eq 5
      end
    end

    context 'when there is an error saving the Authorship' do
      before do
        # Go in and insert invalid data (actor_id has a FK constraint) to
        # force an ActiveRecord Error when trying to update the Authorship
        @wvc1.versions[1].object_changes['actor_id'] = [123456, 123456]
        @wvc1.versions[1].save!
      end

      it 'reports the error, continues to migrate the rest of the creators' do
        authorship_count_before = Authorship.count
        versions_count_before = PaperTrail::Version.count

        errors = perform_call

        expect(errors.length).to eq 1

        expect(errors.first).to match(/WorkVersion##{work_version.id}/i)
          .and match(/foreign key/i)

        # It skips the first creator because it errors out, but continues to
        # migrate the other two (one of which is deleted)
        expect(Authorship.count - authorship_count_before).to eq 1
        expect(PaperTrail::Version.count - versions_count_before).to eq 3
      end
    end
  end

  describe '.migrate_all_work_versions' do
    let(:work_version2) { create :work_version }

    before do
      @act4 = create(:actor, psu_id: 'act004', given_name: 'Actor4')
      @wvc4 = nil

      PaperTrail.request(whodunnit: user.to_gid) do
        Timecop.freeze(Time.zone.local(2021, 1, 8)) do
          @wvc4 = create(
            :work_version_creation,
            work_version: work_version,
            actor: @act4,
            alias: 'Original Alias for Actor 4',
            position: 10
          )
        end
      end
    end

    it 'migrates all work versions' do
      return_value = nil
      expect { return_value = described_class.migrate_all_work_versions }
        .to change(Authorship, :count)
        .by(3)

      expect(return_value).to eq true
    end
  end
end
