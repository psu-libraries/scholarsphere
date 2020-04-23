# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Dashboard::CollectionsController, type: :controller do
  let(:valid_attributes) {
    {
      'title' => 'My Collection',
      'visibility' => Permissions::Visibility.default
    }
  }

  let(:invalid_attributes) {
    {
      'title' => ''
    }
  }

  let(:user) { collection.depositor.user }
  let(:collection) { create :collection }

  describe 'GET #index' do
    context 'when signed in' do
      before do
        collection # Ensure collection is created
        log_in user
      end

      it 'returns a success response' do
        get :index
        expect(response).to be_successful
      end

      it 'shows only my collections' do
        _someone_elses_collection = create :collection
        get :index
        expect(assigns(:collections).map(&:id)).to contain_exactly(collection.id)
      end
    end

    context 'when not signed in' do
      subject { response }

      before { get :index }

      it { is_expected.to redirect_to new_user_session_path }
    end
  end

  describe 'GET #new' do
    context 'when signed in' do
      before do
        log_in user
        get :new
      end

      it 'returns a success response' do
        expect(response).to be_successful
      end

      it 'builds a collection' do
        expect(assigns(:collection)).to be_a Collection
        expect(assigns(:collection).depositor).to eq user.actor
      end
    end

    context 'when not signed in' do
      subject { response }

      before { get :new }

      it { is_expected.to redirect_to new_user_session_path }
    end
  end

  describe 'POST #create' do
    context 'when signed in' do
      before { sign_in user }

      context 'with valid params' do
        it 'creates a new Collection for the current user' do
          expect {
            post :create, params: { collection: valid_attributes }
          }.to change { user.actor.deposited_collections.count }.by(1)
        end

        it 'redirects to the created collection' do
          post :create, params: { collection: valid_attributes }
          expect(response).to redirect_to(dashboard_collections_path) # WIP
        end
      end

      context 'with invalid params' do
        it "returns a success response (i.e. to display the 'new' template)" do
          post :create, params: { collection: invalid_attributes }
          expect(response).to be_successful
        end
      end
    end

    context 'when not signed in' do
      subject { response }

      before { post :create, params: { collection: valid_attributes } }

      it { is_expected.to redirect_to new_user_session_path }
    end
  end

  describe 'GET #show' do
    let(:perform_request) { get :show, params: { id: collection.to_param } }

    it_behaves_like 'an authorized dashboard controller'

    context 'when signed in' do
      before { sign_in user }

      context 'when requesting a version of my own work' do
        it 'returns a success response' do
          perform_request
          expect(response).to be_successful
        end
      end
    end
  end

  describe 'GET #edit' do
    let(:perform_request) { get :edit, params: { id: collection.to_param } }

    it_behaves_like 'an authorized dashboard controller'

    context 'when signed in' do
      before { sign_in user }

      it 'returns a success response' do
        perform_request
        expect(response).to be_successful
      end
    end
  end

  describe 'PATCH #update' do
    let(:invalid_attributes) { { 'title' => '' } }
    let(:valid_attributes) { { 'title' => 'My Edited Title' } }
    let(:attributes) { valid_attributes }
    let(:perform_request) { patch :update, params: { id: collection.to_param, collection: attributes } }

    it_behaves_like 'an authorized dashboard controller'

    context 'when signed in' do
      before { sign_in user }

      context 'with valid attributes' do
        let(:attributes) { valid_attributes }

        before { perform_request }

        its(:response) { is_expected.to redirect_to dashboard_collection_path(collection) }
      end

      context 'with invalid attributes' do
        let(:attributes) { invalid_attributes }

        before { perform_request }

        it { is_expected.to render_template(:edit) }
      end
    end
  end

  describe 'DELETE #destroy' do
    let(:someone_elses_collection) { create :collection }

    context 'when signed in' do
      before { sign_in user }

      context 'when the user owns the collection' do
        it 'destroys the requested collection' do
          expect {
            delete :destroy, params: { id: collection.to_param }
          }.to change(Collection, :count).by(-1)
        end

        it 'redirects to the collections list' do
          delete :destroy, params: { id: collection.to_param }
          expect(response).to redirect_to(dashboard_collections_url)
        end
      end

      context 'when the user does not own the collection' do
        it '404s' do
          expect {
            delete :destroy, params: { id: someone_elses_collection.to_param }
          }.to raise_error(ActiveRecord::RecordNotFound)
        end
      end
    end

    context 'when not signed in' do
      subject { response }

      before { delete :destroy, params: { id: collection.to_param } }

      it { is_expected.to redirect_to new_user_session_path }
    end
  end
end
