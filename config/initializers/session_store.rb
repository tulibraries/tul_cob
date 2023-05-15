# frozen_string_literal: true

# Be sure to restart your server when you modify this file.


if ENV["K8"] == "yes"
  require "action_dispatch/middleware/session/dalli_store"
  Rails.application.config.session_store :dalli_store, "_tulcob_session"
else
  Rails.application.config.session_store :cookie_store, key: "_tulcob_session"
end
