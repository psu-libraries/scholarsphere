# frozen_string_literal: true

source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby '2.6.3'

gem 'aasm'
gem 'blacklight', github: 'projectblacklight/blacklight', branch: 'master'
gem 'bootsnap', '>= 1.4.2', require: false
gem 'bootstrap', '~> 4.0'
gem 'cocoon'
gem 'devise', '~> 4.7'
gem 'diffy'
gem 'faraday', '~> 0.17.0'
gem 'figaro'
gem 'jbuilder', '~> 2.7'
gem 'jquery-rails'
gem 'jsonb_accessor', '~> 1.0.0'
gem 'okcomputer', '~> 1.18.0'
gem 'omniauth-oauth2', '~> 1.6'
gem 'paper_trail'
gem 'pg', '>= 0.18', '< 2.0'
gem 'puma', '~> 3.12'
gem 'pundit'
gem 'qa'
gem 'rails', '~> 6.0.0'
gem 'rsolr', '>= 1.0', '< 3'
gem 'sass-rails', '~> 5'
gem 'scholarsphere-client', github: 'psu-stewardship/scholarsphere-client', branch: 'master'
gem 'shrine', '~> 3.0'
gem 'sidekiq', '~> 6.0'
gem 'uppy-s3_multipart', '~> 0.3'
gem 'webpacker', '~> 4.0'

# Experimental
gem 'actionview-component'

group :development, :test do
  gem 'byebug', platform: :mri
  gem 'database_cleaner'
  gem 'factory_bot_rails'
  gem 'faker'
  gem 'niftany'
  gem 'pry-byebug'
  gem 'pry-rails'
end

group :development do
  gem 'better_errors'
  gem 'binding_of_caller'
  gem 'flog'
  gem 'listen', '>= 3.0.5', '< 3.2'
  gem 'seedbank'
  gem 'spring'
  gem 'spring-commands-rspec'
  gem 'spring-watcher-listen', '~> 2.0.0'
  gem 'web-console', '>= 3.3.0'
  gem 'xray-rails'
end

group :test do
  gem 'capybara'
  gem 'launchy'
  gem 'rails-controller-testing'
  gem 'rspec'
  gem 'rspec-its'
  gem 'rspec-rails', '~> 4.0.0.beta3'
  gem 'selenium-webdriver'
  gem 'shoulda-matchers', '~> 3.1'
  gem 'simplecov', require: false
  gem 'vcr'
  gem 'webdrivers'
  gem 'webmock'
end
