Rails.application.config.features[:login_disabled] = ENV["RAILS_LOGIN_DISABLED"] || false
Rails.application.config.features[:email_document_action_disabled] = ENV["EMAIL_DOCUMENT_ACTION_DISABLED"] || false
Rails.application.config.features[:sms_document_action_disabled] = ENV["SMS_DOCUMENT_ACTION_DISABLED"] || false
