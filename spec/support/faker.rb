# frozen_string_literal: true

RSpec.configure do |config|
  config.before :suite do
    if ENV.key?('FAKER_SEED')

      Faker::Config.random = Random.new(ENV['FAKER_SEED'].to_i)
    end
  end

  config.after :suite do
    # Intentionally left blank.
  end
end
