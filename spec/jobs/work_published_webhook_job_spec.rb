# frozen_string_literal: true

require 'rails_helper'

RSpec.describe WorkPublishedWebhookJob do
  let(:webhook) { instance_double WorkPublishedWebhook, notify: nil }

  before do
    allow(WorkPublishedWebhook).to receive(:new).with('abc123').and_return(webhook)
  end

  describe '#perform' do
    it 'triggers a work published webhook' do
      described_class.perform_now('abc123')

      expect(webhook).to have_received(:notify)
    end
  end
end
