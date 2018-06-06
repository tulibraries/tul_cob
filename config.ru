# frozen_string_literal: true

# This file is used by Rack-based servers to start the application.

require_relative "config/environment"

if ENV["HOSTNAME"] == "libqa.library.temple.edu"
  map "catalog" do
    run Rails.application
  end
else
  run Rails.application
end
