# frozen_string_literal: true

Rails.application.config.features[:login_disabled] = ENV["RAILS_LOGIN_DISABLED"] || false
Rails.application.config.features[:email_document_action_disabled] = ENV["EMAIL_DOCUMENT_ACTION_DISABLED"] || false
Rails.application.config.features[:sms_document_action_disabled] = ENV["SMS_DOCUMENT_ACTION_DISABLED"] || false

# Deaults to false. If env var is set, will only evaluate to false if the value is "false". All others values evaluate to true
Rails.configuration.features[:campus_closed] = (ENV.fetch("CAMPUS_CLOSED", "false") == "false") ? false : true
Rails.configuration.features[:with_libguides] = (ENV.fetch("WITH_LIBGUIDES", "false") == "false") ? false : true
Rails.configuration.features[:libwizard_tutorial] = (ENV.fetch("LIBWIZARD_TUTORIAL", "false") == "false") ? false : true
