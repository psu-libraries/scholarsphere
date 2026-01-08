# frozen_string_literal: true

source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby '3.4.1'

gem 'aasm'
gem 'after_commit_everywhere', '~> 0.1', '>= 0.1.5'
gem 'airrecord'
gem 'blacklight', '~> 7.38'
gem 'blacklight_oai_provider', github: 'projectblacklight/blacklight_oai_provider', ref: '7728dba'
gem 'bootsnap', '>= 1.4.2', require: false
gem 'bot_challenge_page', '~> 0.3.1'
gem 'browser'
gem 'bugsnag', '~> 6.26'
gem 'cocoon'
gem 'devise', '>4.8.0'
gem 'diffy'
gem 'down'
gem 'edtf'
gem 'edtf-humanize'
gem 'faraday', '~> 2.0'
gem 'faraday-multipart'
gem 'flamegraph'
gem 'graphql', '~> 1.12'
gem 'image_processing'
gem 'jbuilder', '~> 2.7'
gem 'jquery-rails'
gem 'jsonb_accessor', '~> 1.3.5'
gem 'mail_form', '~> 1.8'
gem 'matrix'
gem 'memory_profiler'
gem 'mutex_m'
gem 'net-imap'
gem 'net-pop'
gem 'net-smtp'
gem 'okcomputer', '~> 1.18.0'
gem 'omniauth', '~> 2.0'
gem 'omniauth-oauth2'
gem 'omniauth-rails_csrf_protection', '~> 1.0'
gem 'paper_trail', '>=15.1.0'
gem 'pdf-reader'
gem 'pg', '>= 0.18', '< 2.0'
gem 'psu_identity', '0.7.2'
gem 'psych', '< 4'
gem 'puma', '~> 6.5'
gem 'pundit'
gem 'qa', '>= 5.13'
gem 'rack-mini-profiler'
gem 'rails', '~> 7.2'
gem 'recaptcha'
gem 'redcarpet', '~> 3.5'
gem 'rexml'
gem 'rsolr', '>= 1.0', '< 3'
gem 'rubyzip', '~> 2.3.0'
gem 'seedbank'
gem 'shakapacker', '~> 9.5'
gem 'shrine', '~> 3.3'
gem 'sidekiq', '~> 6.5'
gem 'sprockets-rails'
gem 'stackprof'
gem 'uppy-s3_multipart', '~> 1.0'
gem 'view_component'

group :development, :test do
  gem 'byebug', platform: :mri
  gem 'database_cleaner', '~> 2.1.0'
  gem 'factory_bot_rails'
  gem 'faker'
  gem 'html_tokenizer', '~> 0.0.8'
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
  gem 'spring', '>=4.0.0'
  gem 'spring-commands-rspec'
  gem 'spring-watcher-listen', '>= 2.1.0'
  gem 'web-console', '>= 3.3.0'
end

# Lock simplecov at 0.17 until issue with test-reporter is solved
# https://github.com/codeclimate/test-reporter/issues/413
group :test do
  gem 'capybara'
  gem 'launchy'
  gem 'rails-controller-testing'
  gem 'rspec', '~> 3.13'
  gem 'rspec-its'
  gem 'rspec-rails', '~> 7.0.1'
  gem 'selenium-webdriver'
  gem 'shoulda-matchers', '~> 4.3'
  gem 'simplecov', '~> 0.17.1', require: false
  gem 'vcr'
  gem 'webmock'
end

group :production do
  gem 'lograge', '~> 0.11'
  gem 'lograge-sql', '~> 2.4'
end
