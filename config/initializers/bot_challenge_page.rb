# frozen_string_literal: true

BotChallengePage.configure do |config|

  # Can globally disable in configuration if desired
  config.enabled = !Rails.env.test? && Rails.configuration.apis.dig(:turnstile, :enabled)

  # Get from CloudFlare Turnstile: https://www.cloudflare.com/application-services/products/turnstile/
  # Some testing keys are also available: https://developers.cloudflare.com/turnstile/troubleshooting/testing/
  #
  # Always pass testing sitekey: "1x00000000000000000000AA"
  config.cf_turnstile_sitekey = Rails.configuration.apis.dig(:turnstile, :sitekey)
  # Always pass testing secret_key: "1x0000000000000000000000000000000AA"
  config.cf_turnstile_secret_key = Rails.configuration.apis.dig(:turnstile, :secret_key)


  # For rate-limiting, we need a rails cache store that keeps state, by default
  # will use `config.action_controller.cache_store` or Rails.cache, but if you'd
  # like to use a separate store database, eg. :
  # config.store = ActiveSupport::Cache::RedisCacheStore.new(url: "...")

  # Filter to omit requests from bot challenge control, executed in controller instance context
  #
  config.skip_when = ->(config) {
    helpers.current_page?(okcomputer_path)
  }

  # Hook after a bot challenge is presented, for logging or other
  # config.after_blocked = ->(bot_challenge_controller) {
  # }


  # How long will a challenge success exempt a session from further challenges?
  # config.session_passed_good_for = 36.hours


  # Functions like to Rails rate_limit `by` parameter, as a configured default.
  # A discriminator or identifier in which a client's requests will be bucketted
  # by rate limit. Normally this gem buckets by IP address subnets. Switching
  # to individual IPs would be much more generous:
  # config.default_limit_by = ->(config) {
  #   request.remote_ip
  #  }

  # When a "pass" cookie is saved, a fingerprint value is stored with it,
  # and subsequent uses of the pass need to have a request that matches
  # fingerprint. By default we insist on IP subnet match, and same user-agent
  # and other headers. But can be customized.
  config.session_valid_fingerprint = ->(request) {
    [
        request.user_agent,
        request.headers["sec-ch-ua-platform"],
        request.headers["accept-encoding"],
      ]
  }

end
