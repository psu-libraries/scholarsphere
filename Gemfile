# frozen_string_literal: true

source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby '2.6.3'

gem 'blacklight', github: 'projectblacklight/blacklight', branch: 'master'
gem 'bootsnap', '>= 1.4.2', require: false
gem 'bootstrap', '~> 4.0'
gem 'jbuilder', '~> 2.7'
gem 'jquery-rails'
gem 'pg', '>= 0.18', '< 2.0'
gem 'puma', '~> 3.11'
gem 'rails', '~> 6.0.0'
gem 'rsolr', '>= 1.0', '< 3'
gem 'sass-rails', '~> 5'
gem 'webpacker', '~> 4.0'

group :development, :test do
  gem 'byebug', platform: :mri
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
  gem 'spring-watcher-listen', '~> 2.0.0'
  gem 'web-console', '>= 3.3.0'
  gem 'xray-rails'
end

group :test do
  gem 'capybara'
  gem 'coveralls', require: false
  gem 'database_cleaner'
  gem 'launchy'
  gem 'rspec'
  gem 'rspec-its'
  gem 'rspec-rails'
  gem 'selenium-webdriver'
  gem 'shoulda-matchers', '~> 3.1'
  gem 'webdrivers'
end
