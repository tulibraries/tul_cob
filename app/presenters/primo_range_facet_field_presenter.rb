class PrimoRangeFacetFieldPresenter < BlacklightRangeLimit::FacetFieldPresenter

    def range_queries
      range ||= response.dig("stats", "stats_fields", facet_field.field, "data") || []

      range.map do |item|
        Blacklight::PrimoCentral::Facets::FacetItem.new(value: item["from"]..item["to"], hits: item["count"])
      end
    end
end
