# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PagesController do
  describe 'GET #home' do
    before do
      Array.new(3).map do
        FactoryBot.create(:featured_resource)
      end
    end

    it 'sets an array of featured resources' do
      get :home
      expect(assigns(:featured_resources)).not_to be_empty
    end
  end
end
