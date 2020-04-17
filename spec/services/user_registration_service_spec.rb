# frozen_string_literal: true

require 'rails_helper'

RSpec.describe UserRegistrationService do
  describe '.call' do
    let(:mock_client) { instance_spy('PennState::SearchService::Client') }

    before do
      allow(PennState::SearchService::Client).to receive(:new).and_return(mock_client)
      allow(mock_client).to receive(:userid).with(user_id).and_return(person)
    end

    context 'when the user exists at Penn State' do
      let(:user_id) { person.user_id }
      let(:person) { create(:person) }

      it 'returns the newly created User, associated with the new Actor' do
        new_user = described_class.call(uid: user_id)
        expect(new_user).to be_persisted
        expect(new_user.access_id).to eq person.user_id
        expect(new_user.email).to eq person.university_email.downcase

        new_user.actor.tap do |actor|
          expect(actor.psu_id).to eq person.user_id
          expect(actor.email).to eq person.university_email
          expect(actor.given_name).to eq person.given_name
          expect(actor.surname).to eq person.family_name
        end

        expect(new_user.groups.length).to eq 2
        expect(new_user.groups.map(&:name)).to contain_exactly(
          Group::AUTHORIZED_AGENT_NAME,
          Group::PUBLIC_AGENT_NAME
        )
      end
    end

    context 'when the user does not exist a Penn State' do
      let(:user_id) { 'nothere401' }
      let(:person) { nil }

      it 'returns nil with no changes to the database' do
        expect(described_class.call(uid: user_id)).to be_nil
      end
    end

    context 'when the user already exists in the database' do
      let(:user_id) { person.user_id }
      let(:person) { create(:person) }

      before { create(:user, access_id: user_id) }

      it 'returns the existing user without any changes' do
        allow(User).to receive(:from_omniauth)
        described_class.call(uid: user_id)
        expect(User).not_to have_received(:from_omniauth)
      end
    end
  end
end
