# frozen_string_literal: true

module Scholarsphere
  class RedisConfig

    def host
      ENV.fetch('REDIS_HOST', nil)
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

    def valid?
      return true if host
      false
    end

    def to_hash
      {
        url: "redis://#{host}:#{port}/#{database}",
        password: password
      }
    end
  end
end
