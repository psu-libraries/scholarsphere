# frozen_string_literal: true

require 'scholarsphere/cleaner'

RSpec.configure do |config|
  config.before do
    ActionMailer::Base.deliveries.clear
  end

  config.before :suite do
    Scholarsphere::Cleaner.clean
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
    Scholarsphere::Cleaner.clean_solr
    DatabaseCleaner.clean
  end
end
