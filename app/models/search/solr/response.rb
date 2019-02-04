# frozen_string_literal: true

module Search::Solr
  class Response < Blacklight::Solr::Response
    def merge_facet(name:, value:, hits: nil)
      if self.dig("facet_counts", "facet_fields", name)
        self["facet_counts"]["facet_fields"][name].append(value, hits)
      else
        self["facet_counts"]["facet_fields"][name] = [ value, hits ]
      end
    end
  end
end
