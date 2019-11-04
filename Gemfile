# frozen_string_literal: true

source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby '2.6.3'

gem 'aasm'
gem 'blacklight', github: 'projectblacklight/blacklight', branch: 'master'
gem 'bootsnap', '>= 1.4.2', require: false
gem 'bootstrap', '~> 4.0'
gem 'devise', '~> 4.7'
gem 'faraday', '~> 0.17.0'
gem 'figaro'
gem 'jbuilder', '~> 2.7'
gem 'jquery-rails'
gem 'jsonb_accessor', '~> 1.0.0'
gem 'okcomputer', '~> 1.18.0'
gem 'omniauth-oauth2', '~> 1.6'
gem 'pg', '>= 0.18', '< 2.0'
gem 'puma', '~> 3.11'
gem 'pundit'
gem 'rails', '~> 6.0.0'
gem 'rsolr', '>= 1.0', '< 3'
gem 'sass-rails', '~> 5'
gem 'shrine', '~> 3.0'
gem 'uppy-s3_multipart', '~> 0.3'
gem 'webpacker', '~> 4.0'

group :development, :test do
  gem 'byebug', platform: :mri
  gem 'factory_bot_rails'
  gem 'faker'
  gem 'niftany'
  gem 'pry-byebug'
  gem 'pry-rails'
  gem 'solr_wrapper', '>= 0.3'
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
  gem 'xray-rails'
end

group :test do
  gem 'capybara'
  gem 'database_cleaner'
  gem 'launchy'
  gem 'rails-controller-testing'
  gem 'rspec'
  gem 'rspec-its'
  gem 'rspec-rails', '~> 4.0.0.beta3'
  gem 'selenium-webdriver'
  gem 'shoulda-matchers', '~> 3.1'
  gem 'simplecov', require: false
  gem 'webdrivers'
end
