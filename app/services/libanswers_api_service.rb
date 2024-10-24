# frozen_string_literal: true

class LibanswersApiService
  class LibanswersApiError < StandardError; end
  attr_reader :work

  def admin_create_curation_ticket(ticket_type, work_id)
    @work = Work.find(work_id)
    conn = create_connection
    response = conn.post(create_ticket_path, "quid=#{scholarsphere_queue_id(ticket_type)}&" +
                                             "pquestion=#{admin_subject(ticket_type)}&" +
                                             "pname=#{work.display_name}&" +
                                             "pemail=#{work.email}")
    handle_response(response)
    rescue Faraday::ConnectionFailed => e
      raise LibanswersApiError, e.message
  end

  def request_alternate_format(request)
    conn = create_connection
    response = conn.post(create_ticket_path,
    "quid=#{scholarsphere_queue_id('accessibility')}&" +
    "pquestion=Scholarsphere Alternate Format Request: #{request.title}&" +
    "pname=#{request.name}&" +
    "pemail=#{request.email}&" +
    "pdetails=#{request.message} | Work url: #{request.url}&"
    )

    handle_response(response)
    rescue Faraday::ConnectionFailed => e
      raise LibanswersApiError, e.message
  end

  private
    def create_connection
      conn = Faraday.new(url: host) do |f|
        f.headers['Authorization'] = "Bearer #{oauth_token}"
      end
      conn
    end

    def handle_response(response)
      if response.env.status == 200
        host + JSON.parse(response.env.response_body)['ticketUrl']
      else
        raise LibanswersApiError, JSON.parse(response.env.response_body)['error']
      end
    end

    def admin_subject(ticket_type)
      if ticket_type == 'curation'
        "ScholarSphere Deposit Curation: #{work.latest_version.title}"
      else
        "ScholarSphere Deposit Accessibility Curation: #{work.latest_version.title}"
      end
    end

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

    def scholarsphere_queue_id(ticket_type)
      ticket_type == 'curation' ? '5477' : '2590'
    end
end
