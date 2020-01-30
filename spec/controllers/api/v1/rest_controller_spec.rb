# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Api::V1::RestController, type: :controller do
  # @note Create an anonymous controller to test the features of our base class
  controller do
    def index
      render plain: 'success'
    end
  end

  it { is_expected.not_to be_a(ApplicationController) }
  it { is_expected.to be_a(ActionController::Base) }

  context 'with an unauthenticated request' do
    subject { response }

    before { get :index }

    # @note Currently, any request will be allowed until we decide on an authentication framework for the API
    its(:body) { is_expected.to eq('success') }
  end
end
