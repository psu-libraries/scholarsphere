# frozen_string_literal: true

RSpec.configure do |_config|
  Capybara.javascript_driver = :selenium_chrome_headless
end

Capybara.register_driver :selenium_chrome_headless do |app|
  options = ::Selenium::WebDriver::Chrome::Options.new

  options.add_argument('--headless=new')
  options.add_argument('--no-sandbox')
  options.add_argument('--disable-dev-shm-usage')
  options.add_argument('--window-size=1400,1400')
  options.add_argument('--disable-site-isolation-trials')

  Capybara::Selenium::Driver.new(app, browser: :chrome, options: options)
end

Capybara.register_driver :selenium_remote do |app|
  capabilities = Selenium::WebDriver::Remote::Capabilities.chrome(
    chromeOptions: { args: [
      'headless',
      'no-sandbox',
      'disable-gpu',
      'window-size=1024,768',
      'single-process'
    ] }
  )
  Capybara.server_port = '3002'
  Capybara.server_host = '0.0.0.0'
  Capybara.app_host = "http://#{ENV['APP_HOST']}:#{Capybara.server_port}"
  Capybara::Selenium::Driver.new(app,
                                 browser: :remote,
                                 desired_capabilities: capabilities,
                                 url: ENV['SELENIUM_URL'].to_s)
end
