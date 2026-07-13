# frozen_string_literal: true

module Webhooks
  class WorkPublishedWebhook < BaseWebhook
    private

      def webhook_path
        '/webhooks/scholarsphere/open_access_work_published'
      end

      def payload_key
        :scholarsphere_work_url
      end
  end
end
