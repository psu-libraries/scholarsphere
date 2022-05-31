# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Dashboard::CollectionsController, type: :controller do
  # TODO this appears to call identity API, we should mock this out
  # This was Adams access account. he left. tests started failing.
  let(:valid_attributes) {
    {
      'editors_form' => {
        'edit_users' => ['djb44']
      }

    }
  }

  let(:invalid_attributes) {
    {
      'editors_form' => {
        'edit_users' => ['not a valid thing']
      }
    }
  }

  let(:collection) { create :collection, depositor: user.actor }

  let(:user) { create :user }

  describe 'GET #edit' do
    context 'when signed in' do
      before do
        log_in user
        get :edit, params: { id: collection.id }
      end

      it 'returns a success response' do
        expect(response).to be_successful
      end
    end

    context 'when not signed in' do
      subject { response }

      before { get :edit, params: { id: collection.id } }

      it { is_expected.to redirect_to root_path }
    end
  end

  describe 'POST #update' do
    let(:perform_request) {
      post :update, params: { id: collection.id }.merge(attributes)
    }

    context 'when signed in' do
      before { sign_in user }

      context 'with valid params' do
        let(:attributes) { valid_attributes }

        before { perform_request }

        it 'redirects to the updated collection settings page' do
          expect(response).to redirect_to(edit_dashboard_collection_path(collection))
        end
      end

      context 'with invalid params' do
        let(:attributes) { invalid_attributes }

        it 're-renders the form' do
          perform_request
          expect(response).to render_template(:edit)
        end
      end

      context 'with an invalid visibility' do
        it 'does nothing' do
          expect {
            post :update, params: { id: collection.id, collection: { visibility: 'bogus' } }
          }.not_to change(collection, :visibility)
        end
      end
    end

    context 'when not signed in' do
      subject { response }

      let(:attributes) { valid_attributes }

      before { perform_request }

      it { is_expected.to redirect_to root_path }
    end
  end

  describe 'DELETE #destroy' do
    let(:users_collection) { create :collection, depositor: user.actor }
    let(:someone_elses_collection) { create :collection }

    context 'when signed in' do
      before { sign_in user }

      context 'when the user owns the collection' do
        let!(:collection) { users_collection }

        it 'destroys the requested collection' do
          expect {
            delete :destroy, params: { id: collection.to_param }
          }.to change(Collection, :count).by(-1)
        end

        it 'redirects to the collections list' do
          delete :destroy, params: { id: collection.to_param }
          expect(response).to redirect_to(dashboard_root_path)
        end
      end

      context 'with an admin' do
        let!(:collection) { someone_elses_collection }

        let(:user) { create(:user, :admin) }

        it "destroys the other user's collection" do
          expect {
            delete :destroy, params: { id: collection.to_param }
          }.to change(Collection, :count).by(-1)
        end
      end

      context 'when the user does not own the collection' do
        let!(:collection) { someone_elses_collection }

        it 'raises a Pundit error' do
          expect {
            delete :destroy, params: { id: collection.to_param }
          }.to raise_error(Pundit::NotAuthorizedError)
        end
      end
    end

    context 'when not signed in' do
      subject { response }

      let!(:collection) { users_collection }

      before { delete :destroy, params: { id: collection.to_param } }

      it { is_expected.to redirect_to root_path }
    end
  end
end
