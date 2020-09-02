# frozen_string_literal: true

class LibGuidesApi
  attr_reader :query

  class << self
    alias fetch new
  end

  def initialize(query)
    @query = query
  end

  def api_key
    config["api_key"]
  end

  def site_id
    config["site_id"]
  end

  def config
    Rails.configuration.lib_guides
  end

  def as_json(*)
    guides
  end

  private

    def guides
      json.take(3)
    end

    def json
      JSON.parse(response)
    rescue JSON::ParserError => e
      Honeybadger.notify("Parsing LibGuides JSON response at #{url} failed with #{e}")
      []
    end

    def response
      @response ||= begin
        http = HTTParty.get(url)

        if http.success?
          http.body
        else
          "[]"
        end
      end
    rescue => e
      Honeybadger.notify("Parsing LibGuides JSON response at #{url} failed with #{e}")
      "[]"
    end

    def url
      query_terms = {
        site_id: site_id,
        key: api_key,
        sort_by: "relevance",
        search_terms: "#{query}"
      }

      URI::HTTPS.build(
        host: "example.com",
        path: "/1.1/guides",
        query: query_terms.to_query
      ).to_s
    end
end
