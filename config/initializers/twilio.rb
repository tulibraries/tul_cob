# frozen_string_literal: true

twilio_config = YAML.load_file("config/twilio.yml")[(ENV["RAILS_ENV"] || "development")]

ENV["TWILIO_ACCOUNT_SID"] ||= twilio_config['account_sid']
ENV["TWILIO_AUTH_TOKEN"] ||= twilio_config['auth_token']
ENV["TWILIO_PHONE_NUMBER"] ||= twilio_config['phone_number']
ENV["TO_PHONE_NUMBER"] ||= twilio_config['to_phone_number']
