# frozen_string_literal: true

require 'scholarsphere/cleaner'

RSpec.configure do |config|
  config.before do
    ActionMailer::Base.deliveries.clear
  end

  config.before :suite do
    Scholarsphere::Cleaner.clean
    DatabaseCleaner.clean_with(:truncation)
    Group.find_or_create_by(name: Group::PUBLIC_AGENT_NAME)
    Group.find_or_create_by(name: Group::AUTHORIZED_AGENT_NAME)
    Group.find_or_create_by(name: Group::PSU_AFFILIATED_AGENT_NAME)
  end

  config.after :suite do
    DatabaseCleaner.clean_with(:truncation)
  end

  config.before do |example|
    # Use transaction strategy by default because it's so much faster. However,
    # it's not compatible with in-browser javascript testing, so fall back to
    # truncation if the spec that we're about to run is tagged with :js.
    DatabaseCleaner.strategy = example.metadata[:js] ? :truncation : :transaction
    DatabaseCleaner.start
  end

  config.after do
    Scholarsphere::Cleaner.clean_solr
    DatabaseCleaner.clean
  end
end
