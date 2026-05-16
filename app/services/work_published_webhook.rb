# frozen_string_literal: true

class WorkPublishedWebhook
  def initialize(work_uuid)
    @work_uuid = work_uuid
  end

  def notify
    conn = Faraday.new(
      url: ENV['RMD_HOST'],
      headers: { 'X-API-KEY' => ENV['RMD_WEBHOOK_SECRET'] }
    )

    conn.post('/webhooks/scholarsphere/open_access_work_published', scholarsphere_work_url: "/resources/#{work_uuid}")
  end

  private

    attr_reader :work_uuid
end
