# frozen_string_literal: true

module CapybaraDrivers
  def sign_in(user: nil)
    OmniAuth.config.test_mode = true
    OmniAuth.config.mock_auth[:psu] = mock_auth_hash(user) if user.present?
  end

  private

    def mock_auth_hash(user)
      build :psu_oauth_response, access_id: user.access_id
    end
end

RSpec.configure do |config|
  config.before(type: :feature) do |example|
    if example.metadata.key?(:with_user)
      sign_in(user: send(example.metadata.fetch(:with_user)))
    else
      sign_in
    end
  end

  config.include CapybaraDrivers, type: :feature
  config.include ActionView::RecordIdentifier, type: :feature
end

Capybara.register_driver :selenium_remote do |app|
  capabilities = Selenium::WebDriver::Remote::Capabilities.chrome(
    chromeOptions: { args: [ 'headless', 'no-sandbox', 'disable-gpu', 'window-size=1024,768', 'single-process'] }
  )
  Capybara.server_port = '3002'
  Capybara.server_host = '0.0.0.0'
  Capybara.app_host = "http://#{ENV['APP_HOST']}:#{Capybara.server_port}"
  Capybara::Selenium::Driver.new(app,
                                 browser: :remote,
                                 desired_capabilities: capabilities,
                                 url: ENV['SELENIUM_URL'].to_s)

end

Capybara.register_driver :selenium_chrome_headless do |app|
  capabilities = Selenium::WebDriver::Remote::Capabilities.chrome(
    chromeOptions: { args: ['no-sandbox', 'disable-gpu', 'window-size=1024,768', 'single-process'] }
  )

  Capybara::Selenium::Driver.new(app, browser: :chrome, desired_capabilities: capabilities)
end

Capybara.javascript_driver = if ci_build?
                              :selenium_remote
                            else
                               :selenium_chrome_headless
