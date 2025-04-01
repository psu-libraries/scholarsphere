# frozen_string_literal: true

class DoiMintingStatus
  STATUSES = %i(
    waiting
    minting
    error
  ).freeze

  STATUSES.each do |status|
    define_method :"#{status}!" do
      set status.to_s
    end

    define_method :"#{status}?" do
      current_status.to_s == status.to_s
    end
  end

  def initialize(resource)
    @resource = resource
  end

  def present?
    resource.present? && current_status.present?
  end

  def blank?
    !present?
  end

  def delete!
    redis.del(key)
  end

  private

    attr_reader :resource

    def current_status
      redis.get(key)
    end

    def key
      "doi:status:#{resource.uuid}"
    end

    def set(new_status)
      redis.set(key, new_status)
    end

    def redis
      @redis ||= Redis.new(Rails.configuration.redis)
    end
end
