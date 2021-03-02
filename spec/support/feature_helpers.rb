# frozen_string_literal: true

require_relative './feature_helpers/dashboard_form'

module FeatureHelpers
  def retry_click(count: 0)
    count = count + 1
    yield
  rescue Selenium::WebDriver::Error::WebDriverError => e
    retry if count < 20
    raise e
  end

  def console_errors
    errors = page.driver.browser.manage.logs.get(:browser)
    if errors.present?
      message = errors.map(&:message).join("\n")
      puts 'JS Errors:'
      puts message
    else
      puts 'JS Errors: none'
    end
  end

  def print_html(selector)
    puts "HTML for #{selector}:"
    puts page.find(selector)['innerHTML']
    puts ''
  end

  def wait_for_modal(limit = Capybara.default_max_wait_time)
    count = 1
    while page.has_selector?('body.modal-open')
      sleep 1
      count = count + 1
      raise StandardError, "modal failed to close after #{limit} seconds" if count == limit
    end
  end
end

RSpec.configure do |config|
  config.before(type: :feature) do |example|
    if user = example.metadata[:with_user]
      login_as(send(user))
    end
  end

  config.include Warden::Test::Helpers, type: :feature
  config.include FeatureHelpers, type: :feature
  config.include ActionView::RecordIdentifier, type: :feature
end
