# frozen_string_literal: true

require 'rails_helper'

RSpec.describe WorkRemovedWebhookJob do
  let(:webhook) { instance_double WorkRemovedWebhook, notify: nil }

  before do
    allow(WorkRemovedWebhook).to receive(:new).with('abc123').and_return(webhook)
  end

  describe '#perform' do
    it 'triggers a work removed webhook' do
      described_class.perform_now('abc123')

      expect(webhook).to have_received(:notify)
    end
  end
end
