# frozen_string_literal: true

class LibanswersService
  attr_reader :send_to_name, :send_to_email, :cc_email_to, :subject, :message

  def initialize(:send_to_name, :send_to_email, :cc_email_to, :subject, :message)
    @send_to_name = send_to_name
    @send_to_email = send_to_email
    @cc_email_to = cc_email_to
    @subject = subject
    @message = message
  end

  def create_ticket
    conn = Faraday.new(url: host) do |f|
      f.headers["Authorization"] = "Bearer #{oauth_token}"
    end
    conn.post(create_ticket_path, "quid=5477&pquestion=#{message}&pname=#{send_to_name}&pemail=#{send_to_email}")
  end

  private

    def oauth_token
      oauth_token_response["access_token"]
    end

    def oauth_token_response
      JSON.parse(Faraday.new(url: host).post(oauth_token_path, { client_id: ENV.fetch('LIBANSWERS_CLIENT_ID'), 
                                                      client_secret: ENV.fetch('LIBANSWERS_CLIENT_SECRET'), 
                                                      grant_type: 'client_credentials' }).env.response_body)
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
end
