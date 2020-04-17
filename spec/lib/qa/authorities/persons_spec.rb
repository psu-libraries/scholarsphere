# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Qa::Authorities::Persons, type: :authority do
  let(:authority) { described_class.new }
  let(:mock_client) { instance_spy('PennState::SearchService::Client') }

  describe '#search' do
    subject(:results) { authority.search(search_term) }

    before do
      allow(PennState::SearchService::Client).to receive(:new).and_return(mock_client)
      allow(mock_client).to receive(:search).and_return(mock_identity_response)
    end

    context 'with results only from our existing creators' do
      let(:formatted_result) do
        {
          given_name: creator.given_name,
          surname: creator.surname,
          psu_id: creator.psu_id,
          default_alias: creator.default_alias,
          email: creator.email,
          orcid: creator.orcid,
          source: 'scholarsphere'
        }
      end

      let(:mock_identity_response) { [] }

      context 'when searching by surname (case insensitive)' do
        let!(:creator) { create(:actor) }
        let(:search_term) { creator.surname.slice(0..3).downcase }

        it { is_expected.to include(formatted_result) }
      end

      context 'when searching by given name (case insensitive)' do
        let!(:creator) { create(:actor) }
        let(:search_term) { creator.given_name.slice(0..3).downcase }

        it { is_expected.to include(formatted_result) }
      end

      context 'when searching by Penn State ID (case insensitive)' do
        let!(:creator) { create(:actor) }
        let(:search_term) { creator.psu_id.capitalize }

        it { is_expected.to include(formatted_result) }
      end

      context 'when no results are returned' do
        let(:search_term) { 'nothing' }

        it { is_expected.to be_empty }
      end
    end

    context "with results from Penn State's identity service" do
      let(:formatted_result) do
        {
          given_name: person.given_name,
          surname: person.surname,
          psu_id: person.user_id,
          default_alias: person.display_name,
          email: person.university_email,
          orcid: '',
          source: 'penn state'
        }
      end

      let(:mock_identity_response) { [person] }
      let(:person) { build(:person) }
      let(:search_term) { 'search query' }

      it { is_expected.to include(formatted_result) }
    end

    context 'with an unsupported person type' do
      let(:bad_actor) { Struct.new('BadActor', :given_name).new('bad actor') }
      let(:mock_identity_response) { [bad_actor] }

      it 'raises an error' do
        expect {
          authority.search(bad_actor.given_name)
        }.to raise_error(NotImplementedError, 'Struct::BadActor is not a valid person')
      end
    end

    context 'when idential records exist from both sources' do
      let!(:creator) { create(:actor) }
      let(:search_term) { creator.surname.slice(0..3) }
      let(:person) { build(:person, access_id: creator.psu_id) }
      let(:mock_identity_response) { [person] }

      it 'prefers the creator record over the Penn State record' do
        expect(results.count).to eq(1)
        expect(results.first[:source]).to eq('scholarsphere')
      end
    end
  end
end
