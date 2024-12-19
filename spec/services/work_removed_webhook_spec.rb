# frozen_string_literal: true

require 'rails_helper'

RSpec.describe WorkRemovedWebhook do
  let(:webhook) { described_class.new('abc123') }

  describe '#notify' do
    let(:faraday_connection) { instance_spy Faraday::Connection }

    before do
      allow(Faraday).to receive(:new).with(
        url: ENV['RMD_HOST'],
        headers: { 'X-API-KEY' => ENV['RMD_WEBHOOK_SECRET'] }
      ).and_return faraday_connection
    end

    it 'posts the URL for the work to the RMD webhook endpoint' do
      webhook.notify

      expect(faraday_connection).to have_received(:post).with(
        '/webhooks/scholarsphere_events',
        publication_url: 'https://scholarsphere.psu.edu/resources/abc123'
      )
    end
  end
end
