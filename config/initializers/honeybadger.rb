# frozen_string_literal: true

# Errors for honeybadger to ignore.
Honeybadger.configure do |config|
  secrets = {
    solrcloud_user: ENV["SOLRCLOUD_USER"],
    solrcloud_password: ENV["SOLRCLOUD_PASSWORD"],
    primo_apikey: Rails.configuration.bento.dig("primo", "apikey"),
    alma_apikey: Rails.configuration.alma["apikey"],
  }

  config.before_notify do |notice|
    # Filter sensitive params
    secrets.each do |secret_name, secret_value|
      notice.error_message.gsub!(secret_value, "[:#{secret_name}]") unless secret_value.blank?
    end

    # Ignore errors that occur during overnight maintenance
    start_time = Time.now.utc.change(hour: 5, min: 0, sec: 0)
    end_time = Time.now.utc.change(hour: 8, min: 30, sec: 0)
    current_time = Time.now.utc

    notice.halt! if current_time.between?(start_time, end_time)
  end
end
