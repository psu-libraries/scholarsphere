# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Qa::Authorities::Users, type: :authority do
  let(:authority) { described_class.new }
  let(:mock_client) { instance_spy('PsuIdentity::SearchService::Client') }

  describe '#search' do
    subject(:results) { authority.search(search_term) }

    before do
      allow(PsuIdentity::SearchService::Client).to receive(:new).and_return(mock_client)
      allow(mock_client).to receive(:search).and_return(mock_identity_response)
    end

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
end
