# frozen_string_literal: true

# Configure timeouts for Solr connections through environment variables
# Solr 9 requires longer timeouts than Solr 8, especially under test load
# These are used by RSolr when making HTTP requests via Faraday

ENV['RSOLR_TIMEOUT'] ||= '60'
ENV['RSOLR_OPEN_TIMEOUT'] ||= '60'
