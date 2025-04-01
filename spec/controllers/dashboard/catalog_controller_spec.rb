# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Dashboard::CatalogController do
  describe '::_prefixes' do
    subject { described_class._prefixes }

    it { is_expected.to contain_exactly('application', 'dashboard/catalog', 'catalog') }
  end

  describe 'GET #index' do
    context 'when signed in' do
      let(:user) { create(:user) }

      before { log_in user }

      it 'returns a success response' do
        get :index
        expect(response).to be_successful
      end
    end

    context 'when not signed in' do
      subject { response }

      before { get :index }

      it { is_expected.to redirect_to root_path }
    end
  end
end
