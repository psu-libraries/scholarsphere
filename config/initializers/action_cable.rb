# Use loaded redis config to set action_cable url
Rails.application.config.action_cable.url = Scholarsphere::RedisConfig.new.to_hash[:url]