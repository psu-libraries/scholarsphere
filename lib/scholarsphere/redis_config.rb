# frozen_string_literal: true

module Scholarsphere
  class RedisConfig
    def host
      ENV.fetch('REDIS_HOST', 'localhost')
    end

    def port
      ENV.fetch('REDIS_PORT', 6379)
    end

    def database
      ENV.fetch('REDIS_DATABASE', 0)
    end

    def password
      ENV.fetch('REDIS_PASSWORD', nil)
    end

    def ttl
      ENV.fetch('REDIS_TTL', 24.hours)
    end

    def to_hash
      return base_config.merge(password: password) if password

      base_config
    end

    private

      def base_config
        {
          url: "redis://#{host}:#{port}/#{database}",
          ttl: ttl
        }
      end
  end
end
