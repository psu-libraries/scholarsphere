# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AuthorshipMigration::RemoveBadActors, type: :model do
  describe '.call' do
    before do
      @good_actor = create :actor
      @bad_actor1 = create :actor, :with_no_identifiers
      @bad_actor2 = create :actor, :with_no_identifiers

      @good_authorship = create :authorship, actor: @good_actor
      @bad_authorship1 = create :authorship, actor: @bad_actor1
      @bad_authorship2 = create :authorship, actor: @bad_actor2
    end

    it 'updates authorships and removes bad actors' do
      expect {
        described_class.call
      }.to change(Actor, :count).by(-2)

      expect(@good_actor.reload).to be_persisted
      expect { @bad_actor1.reload }.to raise_error(ActiveRecord::RecordNotFound)
      expect { @bad_actor2.reload }.to raise_error(ActiveRecord::RecordNotFound)

      expect(@good_authorship.reload.actor_id).to be_present
      expect(@bad_authorship1.reload.actor_id).to be_nil
      expect(@bad_authorship2.reload.actor_id).to be_nil
    end
  end
end
