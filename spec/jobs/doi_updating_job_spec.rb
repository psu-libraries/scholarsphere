# frozen_string_literal: true

require 'rails_helper'

RSpec.describe DoiUpdatingJob do
  describe '#perform' do
    before { allow(DoiService).to receive(:call) }

    it 'calls DoiService' do
      described_class.perform_now('resource')
      expect(DoiService).to have_received(:call).with('resource')
    end
  end
end
