# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Dashboard::WorkSearchController, type: :controller do
  let(:user) { create :user }

  describe 'GET #index' do
    let(:perform_request) { get :index, params: { q: "test query" } }

    let(:mock_search_service) { instance_spy('Blacklight::SearchService') }
    let(:mock_results) { double(documents: [
      double(work_id: 123, title: "title1"),
      double(work_id: 456, title: "title2"),
     ]) }

    before do
      allow(Blacklight::SearchService).to receive(:new).and_return(mock_search_service)
      allow(mock_search_service).to receive(:search_results).and_return(mock_results)
    end

    context 'when signed in' do
      before do
        log_in user
        perform_request
      end

      it 'returns a successful json response' do
        expect(response).to be_successful
        json_response = JSON.parse(response.body)

        expect(Blacklight::SearchService).to have_received(:new)
        expect(json_response).to match_array([
          {"id" => 123, "text" => "title1"},
          {"id" => 456, "text" => "title2"},
        ])
      end
    end

    context 'when not signed in' do
      subject { response }

      before { perform_request }

      it { is_expected.to redirect_to root_path }
    end
  end
end