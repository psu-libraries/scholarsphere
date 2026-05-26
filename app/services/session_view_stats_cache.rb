# frozen_string_literal: true

class SessionViewStatsCache
  DEFAULT_TTL = 24.hours.to_i

  def self.call(session:, resource:)
    redis = Redis.new(Rails.configuration.redis)
    digest = Digest::MD5.hexdigest("#{session.id}#{resource.class.name}#{resource.id}")[0..6]
    key = "vs:#{digest}"

    return false if redis.get(key)

    redis.set(key, true)
    redis.expire(key, ttl)

    true
  end

  def self.ttl
    Integer(ENV['SESSION_VIEW_STATS_CACHE_TTL'], exception: false) || DEFAULT_TTL
  end

  private_class_method :ttl
end
