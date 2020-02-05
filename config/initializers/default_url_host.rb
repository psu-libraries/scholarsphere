# frozen_string_literal: true

default_url_host = ENV['DEFAULT_URL_HOST']
Rails.application.routes.default_url_options[:host] = default_url_host

if default_url_host.blank?
  raise "ENV['DEFAULT_URL_HOST'] is required to be set"
end
