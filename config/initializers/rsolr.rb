# frozen_string_literal: true

# Configure RSolr (Ruby Solr client) connection settings
# Solr 9 can be slower than Solr 8, especially under test load
# Use longer timeouts to prevent spurious "Connection refused" errors

RSolr.options = {
  timeout: 60,  # Increase from default 10s to 60s for test stability
  open_timeout: 60  # Increase from default 10s to 60s
}
