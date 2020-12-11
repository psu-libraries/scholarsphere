# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ErrorsController, type: :controller do
  subject { response }

  let(:non_html_format) do
    ext = Faker::File.extension

    ext == 'html' ? :xml : ext.to_sym
  end

  describe 'GET #not_found' do
    context 'with the default html format' do
      before { get :not_found }

      its(:status) { is_expected.to eq(404) }
    end

    context 'with any other specified format' do
      before { get :not_found, format: :non_html_format }

      its(:status) { is_expected.to eq(404) }
      its(:body) { is_expected.to eq('{"message":"Record not found"}') }
    end
  end

  describe 'GET #server_error' do
    context 'with the default html format' do
      before { get :server_error }

      its(:status) { is_expected.to eq(500) }
    end

    context 'with any other specified format' do
      before { get :server_error, format: :non_html_format }

      its(:status) { is_expected.to eq(500) }
      its(:body) { is_expected.to eq('{"message":"Server error"}') }
    end
  end
end
