# frozen_string_literal: true

def reset_solr
  Blacklight.default_index.connection.delete_by_query('*:*')
  Blacklight.default_index.connection.commit
end

RSpec.configure do |config|
  config.before :suite do
    reset_solr
  end

  config.after do
    reset_solr
  end
end
