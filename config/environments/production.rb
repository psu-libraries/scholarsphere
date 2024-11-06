# frozen_string_literal: true
# require "active_support/core_ext/integer/time"

Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  config.session_store :cookie_store, httponly: true, secure: true

  # Code is not reloaded between requests.
  config.cache_classes = true

  # Eager load code on boot. This eager loads most of Rails and
  # your application in memory, allowing both threaded web servers
  # and those relying on copy on write to perform better.
  # Rake tasks automatically ignore this option for performance.
  config.eager_load = true

  # Full error reports are disabled and caching is turned on.
  config.consider_all_requests_local       = false
  config.action_controller.perform_caching = true

  # Ensures that a master key has been made available in either ENV["RAILS_MASTER_KEY"]
  # or in config/master.key. This key is used to decrypt credentials (and other encrypted files).
  # config.require_master_key = true

  # Disable serving static files from the `/public` folder by default since
  # Apache or NGINX already handles this.
  config.public_file_server.enabled = ENV['RAILS_SERVE_STATIC_FILES'].present?

  # Specifies the header that your server uses for sending files.
  # config.action_dispatch.x_sendfile_header = 'X-Sendfile' # for Apache
  # config.action_dispatch.x_sendfile_header = 'X-Accel-Redirect' # for NGINX

  # Store uploaded files on the local file system (see config/storage.yml for options).
  config.active_storage.service = :local

  # Mount Action Cable outside main process or domain.
  # config.action_cable.mount_path = nil
  # config.action_cable.url = 'wss://example.com/cable'
  # config.action_cable.allowed_request_origins = [ 'http://example.com', /http:\/\/example.*/ ]

  # Force all access to the app over SSL, use Strict-Transport-Security, and use secure cookies.
  # config.force_ssl = true

  # Use the lowest log level to ensure availability of diagnostic information
  # when problems arise.
  config.log_level = :debug

  # Prepend all log lines with the following tags.
  config.log_tags = [:request_id] if ENV['RAILS_LOG_JSON'].blank?

  # Use a different cache store in production.
  # config.cache_store = :mem_cache_store

  # Use a real queuing backend for Active Job (and separate queues per environment).
  # config.active_job.queue_adapter     = :resque
  # config.active_job.queue_name_prefix = "scholarsphere_production"

  config.action_mailer.perform_caching = false
  config.action_mailer.logger = nil
  config.action_mailer.delivery_method = ENV.fetch('MAIL_DELIVERY_METHOD', 'test').to_sym
  config.action_mailer.smtp_settings = {
    address: ENV.fetch('SMTP_ADDRESS', 'localhost'),
    port: ENV.fetch('SMTP_PORT', 25),
    user_name: ENV.fetch('SMTP_USERNAME', nil),
    password: ENV.fetch('SMTP_PASSWORD', nil),
    authentication: ENV.fetch('SMTP_AUTHENTICATION_TYPE', nil)
  }

  # Ignore bad email addresses and do not raise email delivery errors.
  # Set this to true and configure the email server for immediate delivery to raise delivery errors.
  # config.action_mailer.raise_delivery_errors = false

  # Enable locale fallbacks for I18n (makes lookups for any locale fall back to
  # the I18n.default_locale when a translation cannot be found).
  config.i18n.fallbacks = true

  # Send deprecation notices to registered listeners.
  config.active_support.deprecation = :notify

  # Do not dump schema after migrations.
  config.active_record.dump_schema_after_migration = false

  # -------------------------------------------------------------------------------------------------
  #
  # Configure logging
  #
  # -------------------------------------------------------------------------------------------------

  if ENV['RAILS_LOG_TO_STDOUT'].present?
    logger           = ActiveSupport::Logger.new(STDOUT)
    logger.formatter = config.log_formatter
    config.logger    = ActiveSupport::TaggedLogging.new(logger)
  end

  if ENV['LOGRAGE_ENABLED'].present?
    config.lograge.enabled = true

    config.after_initialize do
      require 'lograge/sql/extension'
    end
  end

  if ENV['RAILS_LOG_JSON'].present?
    config.lograge.formatter = Lograge::Formatters::Json.new
    config.log_formatter = JSONLogFormatter.new
  else
    config.log_formatter = ::Logger::Formatter.new
  end

  config.lograge.custom_payload do |controller|
    {
      request_id: controller.request.env['action_dispatch.request_id'],
      user_id: controller.current_user.try(:access_id)
    }
  end

  config.lograge.custom_options = lambda do |event|
    {
      remote_addr: event.payload[:headers][:REMOTE_ADDR],
      x_forwarded_for: event.payload[:headers][:HTTP_X_FORWARDED_FOR]
    }
  end

  # Instead of extracting event as Strings, extract as Hash. You can also extract
  # additional fields to add to the formatter
  config.lograge_sql.extract_event = Proc.new do |event|
    { name: event.payload[:name], duration: event.duration.to_f.round(2), sql: event.payload[:sql] }
  end
  # Format the array of extracted events
  config.lograge_sql.formatter = Proc.new do |sql_queries|
    sql_queries
  end

  # Inserts middleware to perform automatic connection switching.
  # The `database_selector` hash is used to pass options to the DatabaseSelector
  # middleware. The `delay` is used to determine how long to wait after a write
  # to send a subsequent read to the primary.
  #
  # The `database_resolver` class is used by the middleware to determine which
  # database is appropriate to use based on the time delay.
  #
  # The `database_resolver_context` class is used by the middleware to set
  # timestamps for the last write to the primary. The resolver uses the context
  # class timestamps to determine how long to wait before reading from the
  # replica.
  #
  # By default Rails will store a last write timestamp in the session. The
  # DatabaseSelector middleware is designed as such you can define your own
  # strategy for connection switching and pass that into the middleware through
  # these configuration options.
  # config.active_record.database_selector = { delay: 2.seconds }
  # config.active_record.database_resolver = ActiveRecord::Middleware::DatabaseSelector::Resolver
  # config.active_record.database_resolver_context = ActiveRecord::Middleware::DatabaseSelector::Resolver::Session
end
