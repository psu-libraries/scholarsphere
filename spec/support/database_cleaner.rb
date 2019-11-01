# frozen_string_literal: true

RSpec.configure do |config|
  config.before do
    ActionMailer::Base.deliveries.clear
  end

  config.before :suite do
    DatabaseCleaner.clean_with(:truncation)
  end

  config.after :suite do
    DatabaseCleaner.clean_with(:truncation)
  end

  config.before do
    DatabaseCleaner.strategy = :truncation
    DatabaseCleaner.start
  end

  config.after do
    DatabaseCleaner.clean
  end
end
