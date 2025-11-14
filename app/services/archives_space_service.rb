# frozen_string_literal: true

require "faraday"
require "faraday/multipart"
require "json"

class ArchivesSpaceService
  BASE_URL = "https://scrcarchivesspace.temple.edu/staff/api"
  USERNAME = ENV.fetch("ARCHIVESSPACE_USER", "test-user")
  PASSWORD = ENV.fetch("ARCHIVESSPACE_PASSWORD", "test-pass")

  def initialize
    @conn = Faraday.new("https://scrcarchivesspace.temple.edu/staff/api") do |f|
      f.request :multipart
      f.adapter :net_http
    end
  end

  def search(query, types: [], page: 1, page_size: 3)
    token = ensure_token!

    url = "#{BASE_URL}/search"
    params = [
      ["q", query],
      ["page", page],
      ["page_size", page_size],
      ["filter_query[]", "publish:true"],
      ["filter_query[]", "suppressed:false"]
    ]
    types.each { |t| params << ["type[]", t] }

    conn = Faraday.new do |f|
      f.options.params_encoder = Faraday::FlatParamsEncoder
    end

    response = conn.get(url, params.to_h, { "X-ArchivesSpace-Session" => token })
    body = JSON.parse(response.body)
    body["results"] || []
  end

  def refresh_token!
    conn = Faraday.new do |f|
      f.request :multipart
      f.request :url_encoded
      f.adapter Faraday.default_adapter
    end

    payload = { password: Faraday::Multipart::ParamPart.new(PASSWORD, "text/plain") }
    response = conn.post("#{BASE_URL}/users/#{USERNAME}/login", payload)

    unless response.status == 200
      raise "ArchivesSpace login failed (#{response.status}): #{response.body}"
    end

    body = JSON.parse(response.body)
    token = body["session"]

    Rails.cache.write("aspace_session_token_data",
                      { token: token, expires_at: 50.minutes.from_now })

    token
  end

  def ensure_token!
    token_data = Rails.cache.read("aspace_session_token_data")

    if token_data.nil?
      new_token = refresh_token!
      Rails.cache.write("aspace_session_token_data",
                        { token: new_token, expires_at: 50.minutes.from_now })
      return new_token
    end

    expires_at = token_data[:expires_at] || token_data["expires_at"]
    expires_at = Time.parse(expires_at.to_s) unless expires_at.is_a?(Time)

    if expires_at.nil? || expires_at < Time.current
      new_token = refresh_token!
      Rails.cache.write("aspace_session_token_data",
                        { token: new_token, expires_at: 50.minutes.from_now })
      new_token
    else
      token_data[:token] || token_data["token"]
    end
  end
end
