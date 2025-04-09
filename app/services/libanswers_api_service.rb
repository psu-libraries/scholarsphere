# frozen_string_literal: true

class LibanswersApiService
  class LibanswersApiError < StandardError; end
  attr_reader :work

  ACCESSIBILITY_QUEUE_ID = '2590'
  SCHOLARSPHERE_QUEUE_ID = '5477'

  def admin_create_curation_ticket(work_id)
    @work = Work.find(work_id)
    admin_subject = "ScholarSphere Deposit Curation: #{work.latest_version.title}"
    conn = create_connection
    response = conn.post(create_ticket_path, "quid=#{SCHOLARSPHERE_QUEUE_ID}&" +
                                             "pquestion=#{admin_subject}&" +
                                             "pname=#{work.display_name}&" +
                                             "pemail=#{work.email}")
    handle_response(response)
  rescue Faraday::ConnectionFailed => e
    raise LibanswersApiError, e.message
  end

  def admin_create_accessibility_ticket(work_id, base_url)
    @work = Work.find(work_id)
    admin_subject = "ScholarSphere Deposit Accessibility Curation: #{work.latest_version.title}"
    accessibility_check_results = get_accessibility_result_links(work, base_url)
    conn = create_connection
    response = conn.post(create_ticket_path, "quid=#{ACCESSIBILITY_QUEUE_ID}&" +
                                             "pquestion=#{admin_subject}&" +
                                              (accessibility_check_results.empty? ? '' : "pdetails=#{accessibility_check_results}&") +
                                             "pname=#{work.display_name}&" +
                                             "pemail=#{work.email}")
    handle_response(response)
  rescue Faraday::ConnectionFailed => e
    raise LibanswersApiError, e.message
  end

  def request_alternate_format(request)
    conn = create_connection
    response = conn.post(create_ticket_path,
                         "quid=#{'ACCESSIBILITY_QUEUE_ID'}&" +
                         "pquestion=Scholarsphere Alternate Format Request: #{request.title}&" +
                         "pname=#{request.name}&" +
                         "pemail=#{request.email}&" +
                         "pdetails=#{request.message} | Work url: #{request.url}&")
    handle_response(response)
  rescue Faraday::ConnectionFailed => e
    raise LibanswersApiError, e.message
  end

  private

    def get_accessibility_result_links(work, base_url)
      accessibility_check_results = work.latest_version.file_resources.map do |fr|
        "#{fr.file_data['metadata']['filename']}: #{base_url + fr.file_version_memberships&.first&.accessibility_report_download_url}"
      end
      accessibility_check_results.join("\n")
    end

    def create_connection
      Faraday.new(url: host) do |f|
        f.headers['Authorization'] = "Bearer #{oauth_token}"
      end
    end

    def handle_response(response)
      if response.env.status == 200
        host + JSON.parse(response.env.response_body)['ticketUrl']
      else
        raise LibanswersApiError, JSON.parse(response.env.response_body)['error']
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
end
