# frozen_string_literal: true

class LibanswersService

  def get_oauth_token
    @connection ||= Faraday.new(url: host) do |conn|
      conn.request :basic_auth, username, password
      conn.adapter :net_http
    end
  end

  def create_ticket_path
    host + '/api/1.1/ticket/create'
  end

  def oauth_token_path
    host + '/api/1.1/oauth/token'
  end

  def host
    'psu.libanswers.com'
  end
end
