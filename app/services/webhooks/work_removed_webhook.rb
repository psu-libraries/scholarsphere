# frozen_string_literal: true

module Webhooks
  class WorkRemovedWebhook < BaseWebhook
    private

      def webhook_path
        '/webhooks/scholarsphere_events'
      end

      def payload_key
        :publication_url
      end
  end
end
