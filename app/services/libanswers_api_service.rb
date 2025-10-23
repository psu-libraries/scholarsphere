# frozen_string_literal: true

class LibanswersApiService
  class LibanswersApiError < StandardError; end
  attr_reader :work, :collection

  ACCESSIBILITY_QUEUE_ID = '2590'
  SCHOLARSPHERE_QUEUE_ID = '5477'

  def admin_create_ticket(id, type = 'work_curation', base_url = '')
    depositor = get_depositor(id, type)
    if type == 'work_curation' || (type == 'collection' && !depositor.active?)
      raise LibanswersApiError, I18n.t('resources.contact_depositor_button.error_message')
    end

    admin_subject = get_admin_subject(id, type)
    ticket_details = get_ticket_details(id, type, admin_subject, base_url)

    conn = create_connection
    response = conn.post(create_ticket_path, ticket_details)
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

    def get_depositor(id, type)
      deposit_types = {
        'work_curation' => Work,
        'work_accessibility_check' => Work,
        'work_remediation' => Work,
        'collection' => Collection
      }
      deposit = deposit_types[type].find(id)
      deposit.depositor
    end

    def get_admin_subject(id, type)
      case type
      when 'collection'
        collection = Collection.find(id)
        "ScholarSphere Collection Curation: #{collection.metadata['title']}"
      when 'work_curation'
        work = Work.find(id)
        "ScholarSphere Deposit Curation: #{work.latest_version.title}"
      when 'work_accessibility_check'
        work = Work.find(id)
        "ScholarSphere Deposit Accessibility Curation: #{work.latest_version.title}"
      when 'work_remediation'
        work = Work.find(id)
        "ScholarSphere Deposit Autoremediation Check: #{work.latest_version.title}"
      end
    end

    def get_ticket_details(id, type, admin_subject, base_url = '')
      case type
      when 'collection'
        @collection = Collection.find(id)
        depositor = collection.depositor
        "quid=#{SCHOLARSPHERE_QUEUE_ID}&" +
          "pquestion=#{admin_subject}&" +
          "pname=#{depositor.display_name}&" +
          "pemail=#{depositor.email}"
      when 'work_curation'
        @work = Work.find(id)
        "quid=#{SCHOLARSPHERE_QUEUE_ID}&" + "pquestion=#{admin_subject}&" +
          "pname=#{work.display_name}&" + "pemail=#{work.email}"
      when 'work_accessibility_check'
        @work = Work.find(id)
        accessibility_check_results = get_accessibility_result_links(work, base_url)
        "quid=#{ACCESSIBILITY_QUEUE_ID}&" +
          "pquestion=#{admin_subject}&" +
          (accessibility_check_results.empty? ? '' : "pdetails=#{accessibility_check_results}&") +
          "pname=#{work.display_name}&" +
          "pemail=#{work.email}"
      when 'work_remediation'
        @work = Work.find(id)
        "quid=#{ACCESSIBILITY_QUEUE_ID}&" +
          "pquestion=#{admin_subject}&" +
          "pname=#{work.display_name}&" +
          "pemail=#{work.email}"
      end
    end

    def get_accessibility_result_links(work, base_url)
      accessibility_check_results = work.latest_version.file_resources.map do |fr|
        report = fr.file_version_memberships&.first&.accessibility_report_download_url

        "#{fr.file_data['metadata']['filename']}: #{base_url + report}" if report.present?
      end
      accessibility_check_results.compact.join("\n")
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
