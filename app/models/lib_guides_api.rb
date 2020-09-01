# frozen_string_literal: true

class LibGuidesApi
  attr_reader :query

  class << self
    alias fetch new
  end

  def initialize(query)
    @query = query
  end

  def base_url
    config["base_url"]
  end

  def api_key
    config["api_key"]
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
    rescue HTTParty::ConnectionFailed => e
      Honeybadger.notify("Parsing LibGuides JSON response at #{url} failed with #{e}")
      "[]"
    end

    def url
      # TBD
    end
end
