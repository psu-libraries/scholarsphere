# frozen_string_literal: true

Capybara.register_driver :firefox_headless do |app|
  options = Selenium::WebDriver::Firefox::Options.new
  options.add_argument('--headless')
  options.add_argument('--window-size=1920,1080')
  Capybara::Selenium::Driver.new app, browser: :firefox, options: options
end

RSpec.configure do |_config|
  Capybara.javascript_driver = :firefox_headless
end
