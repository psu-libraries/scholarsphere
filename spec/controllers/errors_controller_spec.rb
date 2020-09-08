# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ErrorsController, type: :controller do
  subject { response }

  context 'with a 404 error' do
    before { get :not_found }

    its(:status) { is_expected.to eq(404) }
  end

  context 'with a 500 error' do
    before { get :server_error }

    its(:status) { is_expected.to eq(500) }
  end
end
