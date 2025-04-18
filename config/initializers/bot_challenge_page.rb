# frozen_string_literal: true

Rails.application.config.to_prepare do
  BotChallengePage::BotChallengePageController.bot_challenge_config.enabled = ENV.fetch('RAILS_ENV') != 'test'

  # Get from CloudFlare Turnstile: https://www.cloudflare.com/application-services/products/turnstile/
  # Some testing keys are also available: https://developers.cloudflare.com/turnstile/troubleshooting/testing/
  #
  # Always pass testing sitekey: "1x00000000000000000000AA"
  BotChallengePage::BotChallengePageController.bot_challenge_config
    .cf_turnstile_sitekey = ENV.fetch(
      'CF_SITE_KEY',
      '1x00000000000000000000AA'
    )
  # Always pass testing secret_key: "1x0000000000000000000000000000000AA"
  BotChallengePage::BotChallengePageController.bot_challenge_config
    .cf_turnstile_secret_key = ENV.fetch(
      'CF_SECRET_KEY',
      '1x0000000000000000000000000000000AA'
    )

  BotChallengePage::BotChallengePageController.bot_challenge_config.rate_limited_locations = [
    '/catalog'
  ]

  # allow rate_limit_count requests in rate_limit_period, before issuing challenge
  BotChallengePage::BotChallengePageController.bot_challenge_config.rate_limit_period = 36.hours
  BotChallengePage::BotChallengePageController.bot_challenge_config.rate_limit_count = 3

  BotChallengePage::BotChallengePageController.rack_attack_init
end
