# frozen_string_literal: true

require "faraday"
require "faraday/multipart"
require "json"

class ArchivesSpaceService
  BASE_URL = "https://scrcarchivesspace.temple.edu/staff/api"
  USERNAME = ENV.fetch("ARCHIVESSPACE_USER", "test-user")
  PASSWORD = ENV.fetch("ARCHIVESSPACE_PASSWORD", "test-pass")

  def initialize
    @conn = Faraday.new(url: BASE_URL) do |f|
      f.options.params_encoder = Faraday::FlatParamsEncoder
      f.request :multipart
      f.request :url_encoded
      f.adapter Faraday.default_adapter
    end
  end

  def search(query, types: [], page: 1, page_size: 3)
    token = ensure_token!

    qs =
      [
        "q=#{CGI.escape(query)}",
        "page=#{page}",
        "page_size=#{page_size}",
        "filter_query[]=publish:true",
        "filter_query[]=suppressed:false"
      ] +
      types.map { |t| "type[]=#{t}" }

    url = "#{BASE_URL}/search?#{qs.join("&")}"

    response = @conn.get(url, nil, { "X-ArchivesSpace-Session" => token })
    JSON.parse(response.body)["results"] || []
  end

  def refresh_token!
    payload = {
      password: Faraday::Multipart::ParamPart.new(PASSWORD, "text/plain")
    }

    response = @conn.post("users/#{USERNAME}/login", payload)

    unless response.status == 200
      raise "ArchivesSpace login failed (#{response.status}): #{response.body}"
    end

    body = JSON.parse(response.body)
    token = body["session"]

    Rails.cache.write(
      "aspace_session_token_data",
      { token: token, expires_at: 50.minutes.from_now }
    )

    token
  end

  def ensure_token!
    token_data = Rails.cache.read("aspace_session_token_data")

    if token_data.nil?
      return refresh_token!
    end

    expires_at = token_data[:expires_at]
    expires_at = Time.parse(expires_at.to_s) unless expires_at.is_a?(Time)

    if expires_at < Time.current
      return refresh_token!
    end

    token_data[:token]
  end
end
