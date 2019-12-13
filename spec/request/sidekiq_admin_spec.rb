# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Sidekiq admin', type: :request do
  let(:user) { create(:user) }
  let(:admin_user) { create(:user, :admin) }

  it 'Raises an error when NOT an admin user' do
    sign_in user
    expect { get '/admin/sidekiq' }.to raise_error(ActionController::RoutingError)
  end

  it 'is successful when you ARE an admin user' do
    sign_in admin_user
    get '/admin/sidekiq'
    expect(response.status).to eq 200
    expect(response.body).to include('Sidekiq')
  end

  it 'redirects to login when not logged in' do
    get '/admin/sidekiq'
    expect(response.status).to eq 302
    expect(response.location).to eq 'http://www.example.com/sign_in'
  end
end
