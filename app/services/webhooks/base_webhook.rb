# frozen_string_literal: true

module Webhooks
  class BaseWebhook
    def initialize(work_uuid)
      @work_uuid = work_uuid
    end

    def notify
      return if ENV['RMD_HOST'].blank?

      connection.post(webhook_path, payload)
    end

    private

      attr_reader :work_uuid

      def connection
        Faraday.new(
          url: ENV['RMD_HOST'],
          headers: { 'X-API-KEY' => ENV['RMD_WEBHOOK_SECRET'] }
        )
      end

      def payload
        { payload_key => work_url }
      end

      def work_url
        "https://#{Rails.application.routes.default_url_options[:host]}/resources/#{work_uuid}"
      end
  end
end
