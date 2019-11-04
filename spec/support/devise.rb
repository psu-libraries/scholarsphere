# frozen_string_literal: true

require 'devise'

module DeviseRequestSpecHelpers
  def log_in(user)
    @request.env['devise.mapping'] = Devise.mappings[:user]
    sign_in user
  end
end

RSpec.configure do |config|
  config.include Devise::Test::ControllerHelpers, type: :controller
  config.include DeviseRequestSpecHelpers, type: :controller
end
