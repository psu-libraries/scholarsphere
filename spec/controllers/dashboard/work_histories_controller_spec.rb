# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Dashboard::WorkHistoriesController, type: :controller do
  let(:user) { work.depositor.user }
  let(:work) { create :work }

  describe 'GET #show' do
    let(:perform_request) { get :show, params: { work_id: work.to_param } }

    it_behaves_like 'an authorized dashboard controller'

    context 'when signed in' do
      before { sign_in user }

      context "when I'm authorized to view this work" do
        before { perform_request }

        its(:response) { is_expected.to be_successful }
      end
    end
  end
end
