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

  def self.derived_lib_guides_search_term(solr_response, term = "")
    query =  [term]
    query += _subject_topic_facet_terms(solr_response)
    query.map { |s| "(#{s})" }.join(" OR ")
  end


  private

    def guides
      ranked_by_type.take(3)
    end

    def ranked_by_type
      # The Libguides API has no way to express preference for certain types of guides, the equivalent
      # of a solr boost (^10 ), so we take the original response, sort it by guide type, then do
      # a secondary sort by original order. That way the most relevant subject guides appear at the top
      ranker = { "Subject Guide" => 1, "Topic Guide" => 1, "General Purpose Guide" => 1, "Course Guide" => 2 }
      json.sort_by { |o| [ranker[o["type_label"]], json.index(o) ] }
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
        expand: "owner",
        guide_types: "1,2,3,4", # we don't want internal guides or templates
        status: 1, # we only want published guides
        search_terms: "#{query}"
      }

      URI::HTTPS.build(
        host: "lgapi-us.libapps.com",
        path: "/1.1/guides",
        query: query_terms.to_query
      ).to_s
    end

    def self._subject_topic_facet_terms(response)
      return [] if (response.nil? || !response.respond_to?(:facet_fields))
      (response.facet_fields || {})
      .fetch("subject_topic_facet", [])
        .to_a
        .each_slice(2)
        .map(&:first)
    end
end
