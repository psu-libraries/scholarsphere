# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AuthorshipMigration::CollectionCreationMigration, type: :model do
  let(:collection) { create :collection }

  before do
    # We will create two CollectionCreations, and we need some Actors to be
    # associated with them
    @act1 = create(:actor, psu_id: 'act001', given_name: 'Actor1')
    @act2 = create(:actor, psu_id: 'act002', given_name: 'Actor2')

    @cc1 = nil
    @cc2 = nil

    Timecop.freeze(Time.zone.local(2021, 1, 1)) do
      @cc1 = create(
        :collection_creation,
        collection: collection,
        actor: @act1,
        alias: 'Alias for Actor 1',
        position: 10
      )
    end

    Timecop.freeze(Time.zone.local(2021, 1, 2)) do
      @cc1.update(position: 20)

      @cc2 = create(
        :collection_creation,
        collection: collection,
        actor: @act2,
        alias: 'Alias for Actor 2',
        position: 10
      )
    end
  end

  describe '.call' do
    def perform_call
      described_class.call(collection: collection)
    end

    context 'when on the happy path' do
      it 'creates a corresponding number of Authorship records' do
        expect { perform_call }
          .to change(Authorship, :count)
          .by(2)
      end

      it 'ports over the creators to Authorships' do
        perform_call

        authorship1 = Authorship.find_by(actor_id: @act1)
        expect(authorship1.resource).to eq collection
        expect(authorship1.alias).to eq 'Alias for Actor 1'
        expect(authorship1.given_name).to eq @act1.given_name
        expect(authorship1.surname).to eq @act1.surname
        expect(authorship1.email).to eq @act1.email
        expect(authorship1.position).to eq 20
        expect(authorship1.actor_id).to eq @act1.id
        expect(authorship1.instance_token).to be_present
        expect(authorship1.created_at.to_date).to eq Time.zone.local(2021, 1, 1).to_date
        expect(authorship1.updated_at.to_date).to eq Time.zone.local(2021, 1, 2).to_date

        authorship2 = Authorship.find_by(actor_id: @act2)
        expect(authorship2.alias).to eq 'Alias for Actor 2'
        expect(authorship2.created_at.to_date).to eq Time.zone.local(2021, 1, 2).to_date
        expect(authorship2.updated_at.to_date).to eq Time.zone.local(2021, 1, 2).to_date
      end

      it 'is idempotent' do
        perform_call
        expect { perform_call }.not_to change(Authorship, :count)
      end
    end
  end

  describe '.migrate_all_collections' do
    let(:collection2) { create :collection }

    before do
      @act3 = create(:actor, psu_id: 'act003', given_name: 'Actor3')
      @cc3 = create(
        :collection_creation,
        collection: collection2,
        actor: @act1,
        alias: 'Alias for Actor 3',
        position: 10
      )
    end

    it 'migrates all collecdtions' do
      expect { described_class.migrate_all_collections }
        .to change(Authorship, :count)
        .by(3)
    end
  end
end
