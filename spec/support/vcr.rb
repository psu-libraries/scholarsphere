# frozen_string_literal: true

require 'vcr'

# Fix flaky behavior ("Too many open files - socket(2) for "127.0.0.1" port 9515")
#   - https://github.com/teamcapybara/capybara#gotchas
#   - https://github.com/bblimke/webmock/blob/master/README.md#connecting-on-nethttpstart
WebMock.allow_net_connect!(net_http_connect_on_start: true)

# Allow connections to Docker images and webriver update urls
driver_hosts = Webdrivers::Common.subclasses
  .map(&:base_url)
  .map { |url| URI.parse(url).host }
allowed_hosts = %w(selenium minio solr) + driver_hosts

VCR.configure do |c|
  c.cassette_library_dir = 'spec/fixtures/vcr_cassettes'
  c.hook_into :webmock
  c.configure_rspec_metadata!
  c.allow_http_connections_when_no_cassette = true
  c.ignore_localhost = true
  c.ignore_hosts *allowed_hosts
  c.debug_logger = File.open('log/vcr.log', 'w')
  c.default_cassette_options = { erb: true, update_content_length_header: true }
end
