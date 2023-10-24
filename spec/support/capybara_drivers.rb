# frozen_string_literal: true

RSpec.configure do |_config|
  Capybara.javascript_driver = :chrome_headless
end

Capybara.register_driver :chrome_headless do |app| \
  Capybara::Selenium::Driver.new(
    app,
    browser: :chrome,
    options: Selenium::WebDriver::Chrome::Options.new(
      args: %w[no-sandbox headless disable-gpu]
    )
  )
end