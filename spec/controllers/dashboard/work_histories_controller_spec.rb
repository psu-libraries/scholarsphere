# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Dashboard::WorkHistoriesController, type: :controller do
  describe 'GET #show' do
    let(:perform_request) { get :show, params: { work_id: work.to_param } }

    context 'with a work the user does NOT have access to' do
      let(:work) { create :work, :with_no_access }

      it_behaves_like 'an authorized dashboard controller'
    end

    context 'with a work the user has access to' do
      let(:work) { create :work }

      before do
        sign_in work.depositor.user
        perform_request
      end

      its(:response) { is_expected.to be_successful }
    end
  end
end
