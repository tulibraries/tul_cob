# frozen_string_literal: true

module Search::Solr
  class Response < Blacklight::Solr::Response
    def merge_facet(name:, value:, hits: nil)
      if self.dig("facet_counts", "facet_fields", name)
        # We need to sort on merge or facet item always appends to list.
        sort_proc = blacklight_config.facet_fields[name]&.sort_proc ||
          -> (f) { (v, _) = f; -v.titleize }

        merged = Hash[*facet_fields[name]]
          .merge(value => hits).sort_by(&sort_proc)

        self["facet_counts"]["facet_fields"][name] = merged.to_a.flatten
      else
        self["facet_counts"]["facet_fields"][name] = [ value, hits ]
      end
    end
  end
end
