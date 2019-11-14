# frozen_string_literal: true

module CapybaraDrivers
  def sign_in(user: nil, driver:)
    assign_current_driver(driver)
    OmniAuth.config.test_mode = true
    OmniAuth.config.mock_auth[:psu] = mock_auth_hash(user) if user.present?
  end

  private

    def assign_current_driver(driver)
      register_driver(driver) unless Capybara.drivers.include?(driver)
      Capybara.current_driver = driver
    end

    def register_driver(driver)
      Capybara.register_driver driver do |app|
        capabilities = Selenium::WebDriver::Remote::Capabilities.chrome(chromeOptions: chrome_options)
        if ENV['SELENIUM_URL']
          Capybara.server_port = '3002'
          Capybara.server_host = '0.0.0.0'
          Capybara.app_host = "http://#{ENV['APP_HOST']}:#{Capybara.server_port}"
          Capybara::Selenium::Driver.new(app,
                                         browser: :remote,
                                         desired_capabilities: capabilities,
                                         url: ENV['SELENIUM_URL'].to_s)
        else
          Capybara::Selenium::Driver.new(app,
                                         browser: :chrome,
                                         desired_capabilities: capabilities)
        end
      end
    end

    def chrome_options
      { args: ['no-sandbox', 'disable-gpu', 'window-size=1024,768', 'single-process'] }
    end

    def mock_auth_hash(user)
      build :psu_oauth_response, access_id: user.access_id
    end
end

RSpec.configure do |config|
  config.before(type: :feature) do |example|
    driver = example.metadata.fetch(:with_driver, Capybara.current_driver)

    if example.metadata.key?(:with_user)
      sign_in(user: send(example.metadata.fetch(:with_user)), driver: driver)
    else
      sign_in(driver: driver)
    end
  end

  config.include CapybaraDrivers, type: :feature
end
