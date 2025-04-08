# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Dashboard::WorkVersionsController do
  let(:user) { work_version.depositor.user }
  let(:work_version) { create(:work_version, :draft) }

  describe 'POST #create' do
    let(:user) { work.depositor.user }
    let(:work) { create(:work, versions_count: 1, has_draft: false) }
    let(:perform_request) { post :create, params: { work_id: work.to_param } }

    it_behaves_like 'an authorized dashboard controller'

    context 'when signed in' do
      before { sign_in user }

      context 'when all is well' do
        it 'builds a new work version' do
          latest_published_version = work.latest_published_version
          allow(BuildNewWorkVersion).to receive(:call).and_call_original
          perform_request
          expect(BuildNewWorkVersion).to have_received(:call).with(latest_published_version)
        end

        it 'saves the new work version' do
          expect {
            perform_request
          }.to change {
            work.reload.versions.count
          }.from(1).to(2)
        end

        it 'redirects to the first page in the wizard' do
          perform_request
          new_version = work.reload.draft_version

          expect(response).to redirect_to dashboard_form_work_version_details_path(new_version)
        end
      end

      context 'when the newly built draft version is invalid (highly unlikely)' do
        let(:bad_draft) { build_stubbed(:work_version) }

        before do
          allow(BuildNewWorkVersion).to receive(:call).and_return(bad_draft)
          allow(bad_draft).to receive(:save).and_return(false)
        end

        it 'redirects with an error message' do
          perform_request
          expect(response).to redirect_to dashboard_root_path
        end
      end
    end
  end

  describe 'GET #show' do
    let(:perform_request) { get :show, params: { id: work_version.to_param } }

    context "when requesting a version of another users's work" do
      # Pending: when we disallow viewing of draft versions
      # it_behaves_like 'an authorized dashboard controller'
    end

    context 'when requesting a version of my own work' do
      before { sign_in user }

      it 'returns a success response' do
        perform_request
        expect(response).to be_successful
      end
    end
  end

  describe 'GET #edit' do
    let(:perform_request) { get :edit, params: { id: work_version.to_param } }

    it_behaves_like 'an authorized dashboard controller'

    context 'when signed in' do
      before { sign_in user }

      context 'when requesting a DRAFT version of my own work' do
        it 'returns a success response' do
          perform_request
          expect(response).to be_successful
        end
      end

      context 'when requesting a PUBLISHED version of my own work' do
        let(:work_version) { create(:work_version, :published) }

        it 'returns not authorized' do
          expect {
            perform_request
          }.to raise_error(Pundit::NotAuthorizedError)
        end
      end
    end
  end

  describe 'DELETE #destroy' do
    let(:perform_request) { delete :destroy, params: { id: work_version.to_param } }

    it_behaves_like 'an authorized dashboard controller'

    context 'when signed in' do
      before { sign_in user }

      context 'when I own the work' do
        before { allow(DestroyWorkVersion).to receive(:call) }

        it 'deletes the version' do
          perform_request
          expect(DestroyWorkVersion).to have_received(:call).with(work_version, force: false)
        end

        context 'when destroying the version will also destroy the parent work' do
          before { allow(DestroyWorkVersion).to receive(:call).and_return(nil) }

          specify do
            expect(perform_request).to redirect_to dashboard_root_path
          end
        end

        context 'when destroying the version will not destroy the parent work' do
          let(:parent_work) { work_version.work }
          let(:previous_version) { parent_work.versions[parent_work.versions.length - 2] }

          before { allow(DestroyWorkVersion).to receive(:call).and_call_original }

          it "redirects to the previous versions's resource page" do
            expect(perform_request).to redirect_to resource_path(previous_version.uuid)
          end
        end
      end
    end
  end

  describe 'GET #publish' do
    let(:perform_request) { get :publish, params: { work_version_id: work_version.to_param } }

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

  describe 'GET #diff' do
    let(:work_version) { work.latest_version }
    let(:previous_version) { work.versions.first }

    let(:perform_request) do
      get :diff, params: { work_version_id: work_version.to_param, previous_version_id: previous_version.to_param }
    end

    context 'with a restricted work' do
      let(:work) { create(:work, :with_no_access) }

      it_behaves_like 'an authorized dashboard controller'
    end

    context 'with a public work' do
      let(:work) { create(:work, versions_count: 2, has_draft: false) }

      before { sign_in user }

      it 'returns a success response' do
        perform_request
        expect(response).to be_successful
      end
    end
  end

  describe 'PATCH #update metadata' do
    let(:invalid_attributes) { { 'title' => '' } }
    let(:valid_attributes) { { 'title' => 'My Edited Title' } }
    let(:attributes) { valid_attributes }
    let(:perform_request) { patch :update, params: { id: work_version.to_param, work_version: attributes } }

    it_behaves_like 'an authorized dashboard controller'

    context 'when signed in' do
      before { sign_in user }

      context 'with valid attributes' do
        let(:attributes) { valid_attributes }

        before { perform_request }

        its(:response) { is_expected.to redirect_to dashboard_work_version_publish_path(work_version) }
      end

      context 'with invalid attributes' do
        let(:attributes) { invalid_attributes }

        before { perform_request }

        it { is_expected.to render_template(:edit) }
      end
    end
  end

  describe 'PATCH #update publish' do
    let(:invalid_attributes) { { 'depositor_agreement' => '0' } }
    let(:valid_attributes) { { 'depositor_agreement' => '1' } }
    let(:attributes) { valid_attributes }
    let(:perform_request) do
      patch :update, params: {
        id: work_version.to_param,
        publish: 'publish',
        work_version: attributes
      }
    end
    let(:work_version) { create(:work_version, :able_to_be_published) }

    it_behaves_like 'an authorized dashboard controller'

    context 'when signed in' do
      before { sign_in user }

      context 'with valid attributes' do
        let(:attributes) { valid_attributes }

        before { perform_request }

        its(:response) { is_expected.to redirect_to dashboard_root_path }
      end

      context 'with invalid attributes' do
        let(:attributes) { invalid_attributes }

        before { perform_request }

        it { is_expected.to render_template(:publish) }
      end

      context 'when the work version does not have all attributes required to be published' do
        let(:work_version) { create(:work_version, :draft) }

        context 'with valid attributes' do
          let(:attributes) { valid_attributes }

          before { perform_request }

          its(:response) { is_expected.to render_template(:publish) }
        end
      end
    end
  end
end
