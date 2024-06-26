# frozen_string_literal: true

# Be sure to restart your server when you modify this file.


if ENV["K8"] == "yes"
  Rails.application.config.session_store :cache_store, expire_after: 1.day
else
  Rails.application.config.session_store :cookie_store, key: "_tulcob_session"
end
