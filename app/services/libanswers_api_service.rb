# frozen_string_literal: true

class LibanswersApiService
  class LibanswersApiError < StandardError; end
  attr_reader :send_to_name, :send_to_email, :subject, :message

  def initialize(admin_contact_depositor_params = {})
    @send_to_name = admin_contact_depositor_params.fetch(:send_to_name)
    @send_to_email = admin_contact_depositor_params.fetch(:send_to_email)
    @subject = admin_contact_depositor_params.fetch(:subject)
  end

  def create_ticket
    conn = Faraday.new(url: host) do |f|
      f.headers['Authorization'] = "Bearer #{oauth_token}"
    end
    response = conn.post(create_ticket_path, "quid=#{scholarsphere_queue_id}&" +
                                             "pquestion=#{subject}&" +
                                             "pname=#{send_to_name}&" +
                                             "pemail=#{send_to_email}")
    if response.env.status == 200
      host + JSON.parse(response.env.response_body)['ticketUrl']
    else
      raise LibanswersApiError, JSON.parse(response.env.response_body)['error']
    end
  rescue Faraday::ConnectionFailed => e
    raise LibanswersApiError, e.message
  end

  private

    def oauth_token
      JSON.parse(oauth_token_response)['access_token']
    end

    def oauth_token_response
      Faraday.new(url: host).post(oauth_token_path, { client_id: ENV.fetch('LIBANSWERS_CLIENT_ID', 'asdf'),
                                                      client_secret: ENV.fetch('LIBANSWERS_CLIENT_SECRET', 'asdfasdf'),
                                                      grant_type: 'client_credentials' }).env.response_body
    end

    def create_ticket_path
      '/api/1.1/ticket/create'
    end

    def oauth_token_path
      '/api/1.1/oauth/token'
    end

    def host
      'https://psu.libanswers.com'
    end

    def scholarsphere_queue_id
      '5477'
    end
end
