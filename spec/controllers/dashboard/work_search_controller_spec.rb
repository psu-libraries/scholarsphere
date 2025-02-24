# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Dashboard::WorkSearchController, type: :controller do
  let(:user) { create(:user) }

  describe 'GET #index' do
    let(:perform_request) { get :index, params: { q: 'test query', max_documents: 20 } }

    let(:mock_search_service) { instance_spy('Blacklight::SearchService') }
    let(:mock_results) { [
      double(documents: [
               double(work_id: 123, title: 'title1'),
               double(work_id: 456, title: 'title2')
             ]),
      [] # _deprecated_document_list
    ] }

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

        expect(Blacklight::SearchService).to have_received(:new) do |params|
          expect(params[:config]).to be_an_instance_of(Blacklight::Configuration)
          expect(params[:search_builder_class]).to eq Dashboard::MemberWorksSearchBuilder
          expect(params[:current_user]).to be_an_instance_of(UserDecorator)
          expect(params[:current_user].id).to eq user.id
          expect(params[:user_params]).to eq({ q: 'test query*' })
          expect(params[:max_documents]).to eq 20
        end

        expect(mock_search_service).to have_received(:search_results)

        expect(json_response).to contain_exactly({ 'id' => 123, 'text' => 'title1' }, { 'id' => 456, 'text' => 'title2' })
      end

      context 'when the max_documents param is not provided in the request' do
        let(:perform_request) { get :index, params: { q: 'test query' } }

        it 'requests the default number of documents from the search service' do
          expect(Blacklight::SearchService).to have_received(:new) do |params|
            expect(params[:max_documents]).to eq 50
          end
        end
      end
    end

    context 'when not signed in' do
      subject { response }

      before { perform_request }

      it { is_expected.to redirect_to root_path }
    end
  end
end
