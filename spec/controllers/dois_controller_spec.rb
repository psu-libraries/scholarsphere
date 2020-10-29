# frozen_string_literal: true

require 'rails_helper'

RSpec.describe DoisController, type: :controller do
  let(:user) { create(:user) }
  let(:admin) { create(:user, :admin) }

  describe 'POST #create' do
    let(:do_post) { post :create, params: { resource_id: resource.uuid } }

    let(:resource) { create :work, doi: nil }

    before { allow(MintDoiAsync).to receive(:call) }

    context 'when signed in with editing privileges to the work' do
      before { log_in admin }

      context 'with a Work that has no existing doi (happy path)' do
        it 'mints the doi' do
          do_post
          expect(MintDoiAsync).to have_received(:call).with(resource)
        end

        it 'redirects to the resource page' do
          do_post
          expect(response).to redirect_to(resource_path(resource.uuid))
        end
      end

      context 'when happy path, and HTTP_REFERER is set' do
        before { request.env['HTTP_REFERER'] = 'where_i_came_from' }

        it 'redirects me to where I came from' do
          do_post
          expect(response).to redirect_to 'where_i_came_from'
        end
      end

      context 'with a Work that already has a DOI' do
        let(:resource) { create :work, doi: '123/456' }

        it 'does NOT mint a new doi' do
          do_post
          expect(MintDoiAsync).not_to have_received(:call)
        end

        it 'redirects to the resource page' do
          do_post
          expect(response).to redirect_to(resource_path(resource.uuid))
        end
      end

      context 'with a Work that is actively minting a DOI right now' do
        let(:mock_minting_status) { instance_double 'DoiMintingStatus', present?: true }

        before do
          allow(DoiMintingStatus).to receive(:new).with(resource)
            .and_return(mock_minting_status)
        end

        it 'does NOT mint a new doi' do
          do_post
          expect(MintDoiAsync).not_to have_received(:call)
        end

        it 'redirects to the resource page' do
          do_post
          expect(response).to redirect_to(resource_path(resource.uuid))
        end
      end

      context 'with a WorkVersion' do
        let(:resource) { create :work_version, :published }
        let(:parent_work) { resource.work }

        before do
          parent_work.update!(doi: nil) # Ensure we are set up correctly
        end

        it 'mints a doi on the PARENT WORK' do
          do_post
          expect(MintDoiAsync).to have_received(:call).with(parent_work)
        end

        it 'redirects back to the WorkVersion resource page' do
          do_post
          expect(response).to redirect_to(resource_path(resource.uuid))
        end
      end
    end

    context 'when signed in, but lacking editing privileges' do
      before { log_in user }

      it 'does not attempt to mint a doi' do
        expect(MintDoiAsync).not_to have_received(:call)
      end

      specify do
        expect { do_post }.to raise_error(Pundit::NotAuthorizedError)
      end
    end
  end
end
