# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PagesController, type: :controller do
  describe 'GET #home' do
    before do
      Array.new(3).map do
        FactoryBot.create(:work, has_draft: false)
      end
    end

    it 'sets the number of featured works' do
      get :home
      expect(assigns(:featured_works)).to be_present
    end
  end
end
