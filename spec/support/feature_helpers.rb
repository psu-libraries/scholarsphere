# frozen_string_literal: true

module FeatureHelpers
  def sign_in(user: nil)
    OmniAuth.config.test_mode = true
    OmniAuth.config.mock_auth[:psu] = mock_auth_hash(user) if user.present?
  end

  def retry_click(count: 0)
    count = count + 1
    yield
  rescue Selenium::WebDriver::Error::WebDriverError => e
    retry if count < 20
    raise e
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

  config.include FeatureHelpers, type: :feature
  config.include ActionView::RecordIdentifier, type: :feature
end
