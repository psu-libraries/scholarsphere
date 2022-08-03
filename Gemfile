# frozen_string_literal: true

source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby '3.1.2'

gem 'aasm'
gem 'after_commit_everywhere', '~> 0.1', '>= 0.1.5'
gem 'blacklight', '~> 7.14'
gem 'blacklight_oai_provider', github: 'projectblacklight/blacklight_oai_provider', ref: '428da77'
gem 'bootsnap', '>= 1.4.2', require: false
gem 'browser'
gem 'cocoon'
gem 'devise'
gem 'diffy'
gem 'edtf'
gem 'edtf-humanize', github: 'psu-libraries/edtf-humanize', tag: 'v2.1.1'
gem 'faraday', '~> 1.0'
gem 'figaro'
gem 'flamegraph'
gem 'graphql', '~> 1.12'
gem 'image_processing'
gem 'jbuilder', '~> 2.7'
gem 'jquery-rails'
gem 'jsonb_accessor', '~> 1.3.5'
gem 'mail_form', '~> 1.8'
gem 'matrix'
gem 'memory_profiler'
gem 'net-smtp'
gem 'okcomputer', '~> 1.18.0'
gem 'omniauth', '~> 2.0'
gem 'omniauth-oauth2', '~> 1.7'
gem 'omniauth-rails_csrf_protection', '~> 1.0'
gem 'paper_trail'
gem 'pg', '>= 0.18', '< 2.0'
gem 'psu_identity', '0.4.0'
gem 'psych', '< 4'
gem 'puma', '~> 4.3'
gem 'pundit'
gem 'qa'
gem 'rack-mini-profiler'
gem 'rails', '>= 6.1'
gem 'recaptcha'
gem 'redcarpet', '~> 3.5'
gem 'rsolr', '>= 1.0', '< 3'
gem 'rubyzip', '~> 2.3.0'
gem 'seedbank'
gem 'shrine', '~> 3.3'
gem 'sidekiq', '~> 6.4'
gem 'stackprof'
gem 'uppy-s3_multipart', '~> 0.3'
gem 'view_component'
gem 'webpacker', '~> 4.0'

group :development, :test do
  gem 'byebug', platform: :mri
  gem 'database_cleaner'
  gem 'factory_bot_rails'
  gem 'faker'
  gem 'niftany', '~> 0.10'
  gem 'pry-byebug'
  gem 'pry-rails'
  gem 'rubocop'
  gem 'rubocop-performance'
  gem 'rubocop-rails'
  gem 'rubocop-rspec'
  gem 'timecop'
end

group :development do
  gem 'better_errors'
  gem 'binding_of_caller'
  gem 'flog'
  gem 'listen', '~> 3.3'
  gem 'spring'
  gem 'spring-commands-rspec'
  gem 'spring-watcher-listen'
  gem 'web-console', '>= 3.3.0'
end

# Lock simplecov at 0.17 until issue with test-reporter is solved
# https://github.com/codeclimate/test-reporter/issues/413
group :test do
  gem 'capybara'
  gem 'launchy'
  gem 'rails-controller-testing'
  gem 'rspec'
  gem 'rspec-its'
  gem 'rspec-rails'
  gem 'selenium-webdriver'
  gem 'shoulda-matchers', '~> 4.3'
  gem 'simplecov', '~> 0.17.1', require: false
  gem 'vcr'
  gem 'webdrivers'
  gem 'webmock'
end

group :production do
  gem 'ddtrace', '~> 0.34'
  gem 'lograge', '~> 0.11'
  gem 'lograge-sql', '~> 1.1'
end
