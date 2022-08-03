# frozen_string_literal: true

require 'spec_helper'

require_relative '../../../lib/scholarsphere/shrine_config'

RSpec.describe Scholarsphere::ShrineConfig do
  subject { described_class }

  describe '::storages' do
    its(:storages) do
      is_expected.to have_key(:store)
      is_expected.to have_key(:cache)
      is_expected.to have_key(:derivatives)
    end
  end

  describe '::s3_options' do
    context 'when an endpoint is configured' do
      it 'adds additional options to S3' do
        cached_endpoint = ENV.fetch('S3_ENDPOINT', nil)
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
