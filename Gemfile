# frozen_string_literal: true

source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby '2.7.1'

gem 'aasm'
gem 'after_commit_everywhere', '~> 0.1', '>= 0.1.5'
gem 'blacklight', '~> 7.13'
gem 'bootsnap', '>= 1.4.2', require: false
gem 'browser'
gem 'cocoon'
gem 'devise'
gem 'diffy'
gem 'edtf'
gem 'edtf-humanize'
gem 'faraday', '~> 0.17.0'
gem 'figaro'
gem 'graphql', '~> 1.12'
gem 'jbuilder', '~> 2.7'
gem 'jquery-rails'
gem 'jsonb_accessor', '~> 1.0.0'
gem 'mail_form', '~> 1.8'
gem 'okcomputer', '~> 1.18.0'
gem 'omniauth', '~> 2.0'
gem 'omniauth-oauth2', '~> 1.7'
gem 'omniauth-rails_csrf_protection', '~> 1.0'
gem 'paper_trail'
gem 'pg', '>= 0.18', '< 2.0'
gem 'puma', '~> 4.3'
gem 'pundit'
gem 'qa'
gem 'rails', '>= 6.1.3.2'
gem 'recaptcha'
gem 'redcarpet', '~> 3.5'
gem 'rsolr', '>= 1.0', '< 3'
gem 'rubyzip', '~> 2.3.0'
gem 'seedbank'
gem 'shrine', '~> 3.3'
gem 'sidekiq', '~> 6.0'
gem 'uppy-s3_multipart', '~> 0.3'
gem 'view_component'
gem 'webpacker', '~> 4.0'

group :development, :test do
  gem 'byebug', platform: :mri
  gem 'database_cleaner'
  gem 'factory_bot_rails'
  gem 'faker'
  gem 'niftany'
  gem 'pry-byebug'
  gem 'pry-rails'
  gem 'rubocop', '= 0.83.0'
  gem 'rubocop-performance', '= 1.5.2'
  gem 'rubocop-rails', '= 2.5.2'
  gem 'rubocop-rspec', '= 1.39.0'
  gem 'timecop'
end

group :development do
  gem 'better_errors'
  gem 'binding_of_caller'
  gem 'flog'
  gem 'listen', '>= 3.0.5', '< 3.2'
  gem 'spring'
  gem 'spring-commands-rspec'
  gem 'spring-watcher-listen', '~> 2.0.0'
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
  gem 'rspec-rails', '~> 4.0.0.beta3'
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
