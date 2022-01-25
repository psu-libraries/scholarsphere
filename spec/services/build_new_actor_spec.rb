# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BuildNewActor, type: :model do
  describe 'building with no identifier' do
    it 'raises an error' do
      expect {
        described_class.call
      }.to raise_error(ArgumentError, 'You must provide either an Orcid or a Penn State access id')
    end
  end

  describe 'building with a Penn State access id', :vcr do
    context 'with no existing Actor' do
      subject(:actor) { described_class.call(psu_id: 'agw13') }

      it 'returns a new record' do
        expect(actor).not_to be_persisted
        expect(actor.given_name).to eq('Adam')
        expect(actor.surname).to eq('Wead')
        expect(actor.display_name).to eq('Adam Wead')
        expect(actor.email).to eq('agw13@psu.edu')
        expect(actor.psu_id).to eq('agw13')
        expect(actor.orcid).to be_nil
      end
    end

    context 'with an existing Actor' do
      subject(:actor) { described_class.call(psu_id: 'agw13') }

      let!(:existing_actor) { create(:actor, psu_id: 'agw13') }

      it 'returns the existing record' do
        expect(actor).to be_persisted
        expect(actor).to eq(existing_actor)
      end
    end

    context 'when the id does not exist' do
      it 'raises an error' do
        expect {
          described_class.call(psu_id: 'abc123')
        }.to raise_error(PsuIdentity::SearchService::NotFound)
      end
    end
  end

  describe 'building with an Orcid id', :vcr do
    context 'with no existing Actor' do
      subject(:actor) { described_class.call(orcid: '0000000184856532') }

      it 'returns a new record' do
        expect(actor).not_to be_persisted
        expect(actor.given_name).to eq('Adam')
        expect(actor.surname).to eq('Wead')
        expect(actor.display_name).to eq('Dr. Adam Wead')
        expect(actor.email).to eq('agw13@psu.edu')
        expect(actor.psu_id).to be_nil
        expect(actor.orcid).to eq('0000000184856532')
      end
    end

    context 'with an existing Actor' do
      subject(:actor) { described_class.call(orcid: '0000000184856532') }

      let!(:existing_actor) { create(:actor, orcid: '0000000184856532') }

      it 'returns the existing record' do
        expect(actor).to be_persisted
        expect(actor).to eq(existing_actor)
      end
    end

    context 'when the id does not exist' do
      it 'raises an error' do
        expect {
          described_class.call(orcid: 'abc123')
        }.to raise_error(Orcid::NotFound)
      end
    end
  end

  describe 'building with both a Penn State access id and an Orcid id', :vcr do
    context 'when only the Orcid exists' do
      it 'raises an error' do
        expect {
          described_class.call(orcid: '0000000184856532', psu_id: 'abc123')
        }.to raise_error(PsuIdentity::SearchService::NotFound)
      end
    end

    context 'when only the access id exists' do
      it 'raises an error' do
        expect {
          described_class.call(orcid: 'abc123', psu_id: 'agw13')
        }.to raise_error(Orcid::NotFound)
      end
    end

    context 'when both ids exist' do
      let(:actor) { described_class.call(orcid: '0000000195000828', psu_id: 'agw13') }

      it 'prefers the access id' do
        expect(actor).not_to be_persisted
        expect(actor.given_name).to eq('Adam')
        expect(actor.surname).to eq('Wead')
        expect(actor.display_name).to eq('Adam Wead')
        expect(actor.email).to eq('agw13@psu.edu')
        expect(actor.psu_id).to eq('agw13')
        expect(actor.orcid).to eq('0000000195000828')
      end
    end
  end
end
