# frozen_string_literal: true

module IntegrationConfig
  module_function

  def alma(key)
    fallback = config_value(Rails.configuration.alma, key)
    fetch_value([:alma, key], fallback)
  end

  def alma_auth_secret
    fetch_value([:alma, :auth_secret], config_value(Rails.configuration.alma, :auth_secret) || ENV["ALMA_AUTH_SECRET"])
  end

  def primo_api_key
    fallback = ENV["PRIMO_API_KEY"] || config_value(Rails.configuration.bento, :primo, :apikey)
    fetch_value([:primo, :apikey], fallback)
  end

  def lib_guides_api_key
    fallback = ENV["LIB_GUIDES_API_KEY"] || config_value(Rails.configuration.lib_guides, :api_key)
    fetch_value([:lib_guides, :api_key], fallback)
  end

  def lib_guides_site_id
    fallback = ENV["LIB_GUIDES_SITE_ID"] || config_value(Rails.configuration.lib_guides, :site_id) || 17
    fetch_value([:lib_guides, :site_id], fallback)
  end

  def lib_guides_base_url
    fetch_value([:lib_guides, :base_url], "https://lgapi-us.libapps.com/1.1/guides")
  end

  def archives_space_base_url
    fetch_value([:archives_space, :base_url], "https://scrcarchivesspace.temple.edu/staff/api")
  end

  def archives_space_username
    fetch_value([:archives_space, :username], ENV.fetch("ARCHIVESSPACE_USER", "test-user"))
  end

  def archives_space_password
    fetch_value([:archives_space, :password], ENV.fetch("ARCHIVESSPACE_PASSWORD", "test-pass"))
  end

  def archives_space_open_timeout
    value = fetch_value([:archives_space, :open_timeout], ENV.fetch("ARCHIVESSPACE_OPEN_TIMEOUT", "2"))
    coerce_integer(value, 2)
  end

  def archives_space_timeout
    value = fetch_value([:archives_space, :timeout], ENV.fetch("ARCHIVESSPACE_TIMEOUT", "5"))
    coerce_integer(value, 5)
  end

  def quik_pay(key)
    fallback = config_value(Rails.configuration.quik_pay, key)
    fetch_value([:quik_pay, key], fallback)
  end

  def oclc(key)
    fallback = config_value(Rails.configuration.oclc, key)
    fetch_value([:oclc, key], fallback)
  end

  def saml(key)
    fallback = config_value(Rails.configuration.devise, key)
    fetch_value([:saml, key], fallback)
  end

  def cache_setting(key)
    fallback = config_value(Rails.configuration.caches, key)
    fetch_value([:caches, key], fallback)
  end

  def fetch_value(path, fallback)
    value = credentials_value(path)
    value.nil? ? fallback : value
  end

  def credentials_value(path)
    Rails.application.credentials.dig(:integrations, *path)
  rescue ActiveSupport::EncryptedConfiguration::InvalidKeyError
    nil
  end

  def config_value(hash, *path)
    path.reduce(hash) do |memo, key|
      break nil if memo.nil?
      memo[key] || memo[key.to_s] || memo[key.to_sym]
    end
  end

  def coerce_integer(value, default)
    Integer(value)
  rescue ArgumentError, TypeError
    default
  end
end
