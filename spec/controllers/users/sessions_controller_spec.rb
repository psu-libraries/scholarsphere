# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Users::SessionsController, type: :controller do
  # Needed by devise when unit-testing
  before { @request.env['devise.mapping'] = Devise.mappings[:user] }

  it 'inherts from Devise' do
    expect(described_class).to be < Devise::SessionsController
  end

  describe '#new' do
    it 'redirects to PSU Oauth' do
      get(:new)
      expect(response).to redirect_to(user_psu_omniauth_authorize_path)
    end
  end
end
