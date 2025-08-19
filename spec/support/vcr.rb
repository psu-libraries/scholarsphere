# frozen_string_literal: true

require 'vcr'
require 'webmock'

# Fix flaky behavior ("Too many open files - socket(2) for "127.0.0.1" port 9515")
#   - https://github.com/teamcapybara/capybara#gotchas
#   - https://github.com/bblimke/webmock/blob/master/README.md#connecting-on-nethttpstart
WebMock.allow_net_connect!(net_http_connect_on_start: true)

# Allow connections to Docker images and webriver update urls
allowed_hosts = %w(selenium minio solr)

VCR.configure do |c|
  c.cassette_library_dir = 'spec/fixtures/vcr_cassettes'
  c.hook_into :webmock
  c.configure_rspec_metadata!
  c.allow_http_connections_when_no_cassette = true
  c.ignore_localhost = true
  c.ignore_hosts *allowed_hosts
  c.debug_logger = File.open('log/vcr.log', 'w')
  c.default_cassette_options = { erb: true, update_content_length_header: true }
  c.preserve_exact_body_bytes do |http_message|
    http_message.body.encoding.name != 'UTF-8' || !http_message.body.valid_encoding?
  end

  regex = /(SECRET|TOKEN|KEY|PASSWORD|ID|USER)/i
  ENV.each_key do |key|
    c.filter_sensitive_data('<REDACTED>') { ENV[key] if key.match(regex) }
  end

  c.filter_sensitive_data('<AUTH>') { |interaction|
    interaction.request.headers['Authorization']&.first }
end
