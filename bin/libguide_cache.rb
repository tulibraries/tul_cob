#!/usr/bin/env ruby
# frozen_string_literal: true

#
# A script for retrieving a local repository of libguide databases.
#

require "httparty"

client_id = ENV["AZ_CLIENT_ID"]
client_secret = ENV["AZ_CLIENT_SECRET"]
endpoint = "https://lgapi-us.libapps.com/1.2/oauth/token"

response = HTTParty.post(endpoint, body: { client_id: client_id, client_secret: client_secret, grant_type: "client_credentials" })
cred = JSON.parse(response)

endpoint = "https://lgapi-us.libapps.com/1.2/az"
token = cred["access_token"]
response = HTTParty.get(endpoint, headers: { Authorization: "Bearer #{token}" }, query: { expand: "subjects,icons,friendly_url,az_types,az_props,permitted_uses" })

File.open "tmp/cache/databases.json", "w+" do |file|
  file.write(response.body)
end
