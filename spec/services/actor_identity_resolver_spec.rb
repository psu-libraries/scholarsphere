# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ActorIdentityResolver do
  describe '.call' do
    let(:psu_id) { 'jxd123' }
    let(:directory_client) { instance_spy('PsuIdentity::DirectoryService::Client') }

    before do
      allow(PsuIdentity::DirectoryService::Client).to receive(:new).and_return(directory_client)
    end

    context 'when the directory returns an ORCID' do
      before do
        allow(directory_client).to receive(:userid).with(psu_id).and_return(double(orc_id: '0000-0001-8485-6532'))
      end

      it 'returns the normalized ORCID' do
        expect(described_class.call(psu_id: psu_id)).to eq('0000000184856532')
      end
    end

    context 'when the directory has no ORCID' do
      before do
        allow(directory_client).to receive(:userid).with(psu_id).and_return(double(orc_id: nil))
      end

      it 'returns nil' do
        expect(described_class.call(psu_id: psu_id)).to be_nil
      end
    end

    context 'when the directory lookup fails' do
      before do
        allow(directory_client).to receive(:userid).with(psu_id).and_raise(StandardError, 'directory unavailable')
        allow(Rails.logger).to receive(:error)
      end

      it 'logs the error and returns nil' do
        expect(described_class.call(psu_id: psu_id)).to be_nil

        expect(Rails.logger).to have_received(:error).with('Unable to resolve Actor ORCID from PSU ID: directory unavailable')
      end
    end
  end
end
