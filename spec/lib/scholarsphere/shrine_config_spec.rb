# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Scholarsphere::ShrineConfig do
  subject { described_class }

  describe '::storages' do
    its(:storages) { is_expected.to have_key(:store) }
    its(:storages) { is_expected.to have_key(:cache) }
    its(:storages) { is_expected.to have_key(:derivatives) }
  end

  describe '::s3_options' do
    context 'when an endpoint is configured' do
      it 'adds additional options to S3' do
        cached_endpoint = ENV['S3_ENDPOINT']
        ENV['S3_ENDPOINT'] = 'http://some-endpoint'
        expect(described_class.s3_options).to include(endpoint: 'http://some-endpoint', force_path_style: true)
        ENV['S3_ENDPOINT'] = cached_endpoint
      end
    end

    context 'when no endpoint is configured' do
      before { allow(ENV).to receive(:key?).with('S3_ENDPOINT').and_return(false) }

      it 'uses the default configuration' do
        expect(described_class.s3_options).not_to have_key(:endpoint)
        expect(described_class.s3_options).not_to have_key(:force_path_style)
      end
    end
  end
end
