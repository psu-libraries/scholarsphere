# frozen_string_literal: true

RSpec.configure do |_config|
  Capybara.javascript_driver = if ENV['SELENIUM']
                                 :selenium_remote
                               else
                                 :selenium_chrome_headless
                               end
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
  Capybara.app_host = "http://#{ENV.fetch('APP_HOST', nil)}:#{Capybara.server_port}"
  Capybara::Selenium::Driver.new(app,
                                 browser: :remote,
                                 desired_capabilities: capabilities,
                                 url: ENV['SELENIUM_URL'].to_s)
end
