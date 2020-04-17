# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Dashboard::WorksController, type: :controller do
  let(:valid_attributes) {
    {
      'work_type' => Work::Types.all.first,
      'visibility' => Permissions::Visibility.default,
      'versions_attributes' => [
        { 'title' => 'My new work' }
      ]
    }
  }

  let(:invalid_attributes) {
    {
      work_type: ''
    }
  }

  let(:user) { create :user }

  describe 'GET #index' do
    context 'when signed in' do
      let!(:my_work) { create :work, depositor: user.actor }

      before { log_in user }

      it 'returns a success response' do
        get :index
        expect(response).to be_successful
      end

      it 'shows only my works' do
        _someone_elses_work = create :work
        get :index
        expect(assigns(:works).map(&:id)).to contain_exactly(my_work.id)
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

      it 'builds a work with a stubbed version' do
        expect(assigns(:work).versions).not_to be_empty
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
        it 'creates a new Work for the current user' do
          expect {
            post :create, params: { work: valid_attributes }
          }.to change { user.works.count }.by(1)
        end

        it 'redirects to the created work' do
          post :create, params: { work: valid_attributes }
          expect(response).to redirect_to(dashboard_works_path) # WIP
        end
      end

      context 'with invalid params' do
        it "returns a success response (i.e. to display the 'new' template)" do
          post :create, params: { work: invalid_attributes }
          expect(response).to be_successful
        end
      end

      context 'with an invalid visibility' do
        it 'raises an error' do
          expect { post :create, params: { work: { visibility: 'bogus' } } }.to raise_error(ArgumentError)
        end
      end
    end

    context 'when not signed in' do
      subject { response }

      before { post :create, params: { work: valid_attributes } }

      it { is_expected.to redirect_to new_user_session_path }
    end
  end

  describe 'DELETE #destroy' do
    let(:users_work) { create :work, depositor: user.actor }
    let(:someone_elses_work) { create :work }

    context 'when signed in' do
      before { sign_in user }

      context 'when the user owns the work' do
        let!(:work) { users_work }

        it 'destroys the requested work' do
          expect {
            delete :destroy, params: { id: work.to_param }
          }.to change(Work, :count).by(-1)
        end

        it 'redirects to the works list' do
          delete :destroy, params: { id: work.to_param }
          expect(response).to redirect_to(dashboard_works_url)
        end
      end

      context 'when the user does not own the work' do
        let!(:work) { someone_elses_work }

        it '404s' do
          expect {
            delete :destroy, params: { id: work.to_param }
          }.to raise_error(ActiveRecord::RecordNotFound)
        end
      end
    end

    context 'when not signed in' do
      subject { response }

      let!(:work) { users_work }

      before { delete :destroy, params: { id: work.to_param } }

      it { is_expected.to redirect_to new_user_session_path }
    end
  end
end
