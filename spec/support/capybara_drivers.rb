# frozen_string_literal: true

RSpec.configure do |_config|
  Capybara.javascript_driver = :chrome_headless
end

Capybara.register_driver :chrome_headless do |app|
  options = Selenium::WebDriver::Chrome::Options.new
  options.add_argument('--no-sandbox')
  options.add_argument('--headless=new')
  options.add_argument('--disable-dev-shm-usage')
  options.add_argument('--disable-gpu')
  Capybara::Selenium::Driver.new(
    app,
    browser: :chrome,
    options: options
  )
end
