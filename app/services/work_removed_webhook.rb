# frozen_string_literal: true

class WorkRemovedWebhook
  def initialize(work_uuid)
    @work_uuid = work_uuid
  end

  def notify
    conn = Faraday.new(
      url: ENV['RMD_HOST'],
      headers: { 'X-API-KEY' => ENV['RMD_WEBHOOK_SECRET'] }
    )

    conn.post('/webhooks/scholarsphere_events', publication_url: "#{Rails.application.routes.default_url_options[:host]}/resources/#{work_uuid}")
  end

  private

    attr_reader :work_uuid
end
