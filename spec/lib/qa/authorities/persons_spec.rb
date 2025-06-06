# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Qa::Authorities::Persons, type: :authority do
  let(:authority) { described_class.new }
  let(:mock_client) { instance_spy('PsuIdentity::SearchService::Client') }

  describe '#search' do
    subject(:results) { authority.search(search_term) }

    before do
      allow(PsuIdentity::SearchService::Client).to receive(:new).and_return(mock_client)
      allow(mock_client).to receive(:search).and_return(mock_identity_response)
    end

    context 'with results only from our existing creators' do
      let(:formatted_result) do
        {
          given_name: creator.given_name,
          surname: creator.surname,
          psu_id: creator.psu_id,
          display_name: creator.display_name,
          email: creator.email,
          orcid: creator.orcid,
          source: 'scholarsphere',
          actor_id: creator.id,
          result_number: 1,
          total_results: 1,
          additional_metadata: "#{Actor.human_attribute_name(:psu_id)}: #{creator.psu_id}"
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

      context 'when PSU ID is not present, but ORCiD is' do
        let!(:creator) { create(:actor, psu_id: nil) }
        let(:search_term) { creator.surname.slice(0..3).downcase }

        let(:expected_result) { formatted_result.merge(
          additional_metadata: "#{Actor.human_attribute_name(:orcid)}: #{OrcidId.new(creator.orcid).to_human}"
        ) }

        it { is_expected.to include(expected_result) }
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
          display_name: person.display_name,
          email: person.university_email,
          orcid: '',
          source: 'penn state',
          result_number: 1,
          total_results: 1,
          additional_metadata: "#{Actor.human_attribute_name(:psu_id)}: #{person.user_id}"
        }
      end

      let(:mock_identity_response) { [person] }
      let(:person) { build(:person) }
      let(:search_term) { 'search query' }

      it { is_expected.to include(formatted_result) }
    end

    context "when Penn State's identity service contains existing Scholarsphere Actors" do
      let!(:creator) { create(:actor) }

      let(:formatted_result) do
        {
          given_name: creator.given_name,
          surname: creator.surname,
          psu_id: creator.psu_id,
          display_name: creator.display_name,
          email: creator.email,
          orcid: creator.orcid,
          source: 'scholarsphere',
          actor_id: creator.id,
          result_number: 1,
          total_results: 1,
          additional_metadata: "#{Actor.human_attribute_name(:psu_id)}: #{creator.psu_id}"
        }
      end

      let(:mock_identity_response) { [person] }
      let(:person) { build(:person, access_id: creator.psu_id) }
      let(:search_term) { 'search query' }

      it { is_expected.to include(formatted_result) }
    end

    context 'when searching with an Orcid', :vcr do
      let(:formatted_result) do
        {
          given_name: 'Adam',
          surname: 'Wead',
          display_name: 'Dr. Adam Wead',
          email: 'agw13@psu.edu',
          orcid: '0000000184856532',
          source: 'orcid',
          result_number: 1,
          total_results: 1,
          additional_metadata: "#{Actor.human_attribute_name(:orcid)}: #{search_term}"
        }
      end

      let(:mock_identity_response) { [] }
      let(:search_term) { '0000-0001-8485-6532' }

      it { is_expected.to include(formatted_result) }
    end

    context 'when an actor exists with the same Orcid', :vcr do
      let!(:creator) { create(:actor, orcid: search_term) }

      let(:formatted_result) do
        {
          given_name: creator.given_name,
          surname: creator.surname,
          psu_id: creator.psu_id,
          display_name: creator.display_name,
          email: creator.email,
          orcid: creator.orcid,
          source: 'scholarsphere',
          actor_id: creator.id,
          result_number: 1,
          total_results: 1,
          additional_metadata: "#{Actor.human_attribute_name(:psu_id)}: #{creator.psu_id}"
        }
      end

      let(:mock_identity_response) { [] }
      let(:search_term) { '0000000184856532' }

      it { is_expected.to include(formatted_result) }
    end

    context 'with an unsupported person type' do
      let(:bad_actor) { Struct.new('BadActor', :given_name, :user_id).new('bad actor', 'bad123') }
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
