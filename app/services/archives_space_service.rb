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

    response = request_search(query, types, page, page_size, token)
    if [401, 403].include?(response.status)
      token = refresh_token!
      response = request_search(query, types, page, page_size, token)
    end

    parse_search_response(response)
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

  private

  def request_search(query, types, page, page_size, token)
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
    @conn.get(url, nil, { "X-ArchivesSpace-Session" => token })
  end

  def parse_search_response(response)
    content_type = response.headers["content-type"].to_s

    unless response.status == 200
      raise "ArchivesSpace search failed (#{response.status}): #{response_snippet(response)}"
    end

    if content_type.empty? || content_type.include?("json")
      begin
        return JSON.parse(response.body)["results"] || []
      rescue JSON::ParserError => e
        raise "ArchivesSpace search JSON parse error: #{e.message}: #{response_snippet(response)}"
      end
    end

    raise "ArchivesSpace search returned non-JSON content-type (#{content_type}): #{response_snippet(response)}"
  end

  def response_snippet(response)
    body = response.body.to_s
    body = body.gsub(/\s+/, " ").strip
    body[0, 200]
  end
end
