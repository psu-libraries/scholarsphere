# frozen_string_literal: true

module Scholarsphere
  class RedisConfig
    def call
      redis_config
    end

    def redis_host
      ENV.fetch('REDIS_HOST', nil)
    end

    def redis_port
      ENV.fetch('REDIS_PORT', 6379)
    end

    def redis_database
      ENV.fetch('REDIS_DATABASE', 0)
    end

    def redis_password
      ENV.fetch('REDIS_PASSWORD', nil)
    end

    def redis_config
      config = {
        url: "redis://#{redis_host}:#{redis_port}/#{redis_database}",
        password: redis_password
      }
      config
    end
  end
end
