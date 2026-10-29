# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ActorReconciliationService do
  describe '.call' do
    let(:orcid) { '0000000184856532' }
    let!(:psu_actor) { create(:actor, psu_id: 'jxd123', orcid: nil) }
    let!(:orcid_actor) { create(:actor, psu_id: nil, orcid: orcid) }
    let!(:deposited_work) { create(:work, depositor: orcid_actor) }
    let!(:proxy_work) { create(:work, proxy_depositor: orcid_actor) }
    let!(:deposited_collection) { create(:collection, depositor: orcid_actor) }
    let!(:authorship) { create(:authorship, actor: orcid_actor) }
    let!(:authored_collection) { create(:collection) }
    let!(:collection_authorship) do
      create(:authorship, :of_collection, resource: authored_collection, actor: orcid_actor)
    end
    let(:user) { build(:user, access_id: psu_actor.psu_id, actor: psu_actor) }
    let(:resolved_orcid) { orcid }

    before do
      allow(User).to receive(:directory_orcid).with(user.access_id).and_return(resolved_orcid)
    end

    it 'moves associations to the PSU Actor and removes the ORCID-only Actor' do
      expect {
        described_class.call(user: user)
      }.to change(Actor, :count).by(-1)

      expect(user.actor).to eq(psu_actor)
      expect(psu_actor.reload.orcid).to eq(orcid)
      expect(deposited_work.reload.depositor).to eq(psu_actor)
      expect(proxy_work.reload.proxy_depositor).to eq(psu_actor)
      expect(deposited_collection.reload.depositor).to eq(psu_actor)
      expect(authorship.reload.actor).to eq(psu_actor)
      expect(collection_authorship.reload.actor).to eq(psu_actor)
      expect { orcid_actor.reload }.to raise_error(ActiveRecord::RecordNotFound)
    end

    context 'when the directory does not return an ORCID' do
      let(:resolved_orcid) { nil }

      it 'returns the user without reconciling Actors' do
        expect {
          described_class.call(user: user)
        }.not_to change(Actor, :count)

        expect(user.actor).to eq(psu_actor)
        expect(psu_actor.reload.orcid).to be_nil
        expect(orcid_actor.reload).to be_persisted
      end
    end

    context 'when no Actor matches the resolved ORCID' do
      let(:resolved_orcid) { '0000000000000000' }

      it 'returns the user without reconciling Actors' do
        expect {
          described_class.call(user: user)
        }.not_to change(Actor, :count)

        expect(user.actor).to eq(psu_actor)
        expect(psu_actor.reload.orcid).to be_nil
        expect(orcid_actor.reload).to be_persisted
      end
    end
  end
end
