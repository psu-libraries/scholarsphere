# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HealthChecks::VersionCheck do
  describe '#check' do
    context 'when version' do
      before do
        ENV['APP_VERSION'] = '3'
      end

      it 'returns no failure' do
        hc = described_class.new
        hc.check
        expect(hc.failure_occurred).to be_nil
      end

      it 'writes a message' do
        hc = described_class.new
        hc.check
        expect(hc.message).to eq('3')
      end
    end

    context 'when no version' do
      before do
        ENV['APP_VERSION'] = nil
      end

      it 'writes unknown' do
        hc = described_class.new
        hc.check
        expect(hc.message).to eq('unknown')
      end
    end
  end
end
