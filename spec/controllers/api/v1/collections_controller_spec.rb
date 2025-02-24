# frozen_string_literal: true

require 'rails_helper'

# @note While this is technically a controller test, because it's testing our REST API, we're really using it as a
# feature test to ensure end-to-end functionality for migrating collections.

RSpec.describe Api::V1::CollectionsController, type: :controller do
  let(:api_token) { create(:api_token).token }
  let(:user) { build(:actor) }
  let(:creator) do
    {
      display_name: "#{user.given_name} #{user.surname}",
      position: 1,
      actor_attributes: {
        email: user.email,
        given_name: user.given_name,
        surname: user.surname,
        psu_id: user.psu_id
      }
    }
  end
  let(:json_response) { JSON.parse(response.body) }
  let(:new_collection) { Collection.last }

  before { request.headers[:'X-API-Key'] = api_token }

  describe 'POST #create' do
    context 'with valid input' do
      let(:works) do
        Array.new(3).map do
          FactoryBot.create(:work, depositor: user)
        end
      end

      before do
        post :create, params: {
          metadata: {
            title: FactoryBotHelpers.work_title,
            description: Faker::Lorem.paragraph,
            work_ids: works.map(&:id),
            creators_attributes: [creator]
          },
          depositor: { given_name: user.given_name, surname: user.surname, email: user.email, psu_id: user.psu_id }
        }
      end

      it 'creates a new collection' do
        expect(response).to be_ok
        expect(json_response).to include(
          'message' => 'Collection was successfully created',
          'url' => "/resources/#{new_collection.uuid}"
        )
        expect(new_collection.work_ids).to match_array(works.map(&:id))
      end
    end

    context 'with missing parameters' do
      before do
        post :create, params: {
          metadata: { title: FactoryBotHelpers.work_title }
        }
      end

      it 'reports the error with the missing parameter' do
        expect(response).to be_bad_request
        expect(json_response['message']).to eq('Bad request')
        expect(json_response['errors']).to include(/param is missing or the value is empty: depositor/)
      end
    end

    context 'with missing metadata' do
      before do
        post :create, params: {
          metadata: { title: nil },
          depositor: { given_name: user.given_name, surname: user.surname, email: user.email, psu_id: user.psu_id }
        }
      end

      it 'reports the error' do
        expect(response.status).to eq(422)
        expect(json_response).to include(
          'message' => 'Unable to complete the request',
          'errors' => ["Title can't be blank", "Description can't be blank"]
        )
      end
    end
  end
end
