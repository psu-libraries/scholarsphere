# frozen_string_literal: true

class SessionViewStatsCache
  def self.call(session:, resource:)
    redis = Redis.new(Rails.configuration.redis)
    digest = Digest::MD5.hexdigest("#{session.id}#{resource.class.name}#{resource.id}")[0..6]
    key = "vs:#{digest}"

    return false if redis.get(key)

    redis.set(key, true)
    redis.expire(key, Rails.configuration.redis[:ttl])

    true
  end
end
