# frozen_string_literal: true

module BentoSearch
  class CDMEngine
    include BentoSearch::SearchEngine

    delegate :blacklight_config, to: ::SearchController

    def search_implementation(args)
      query = args.fetch(:query, "")

      # Avoid making a costly call for no reason.
      if query.empty?
        response = { "docs" => [] }
      else
        response = CDM::find(query)
      end

      results = BentoSearch::Results.new
      results.total_items = response.dig("results", "pager", "total") || 0
      results << BentoSearch::ResultItem.new(custom_data: response)

      results
    end
  end
end
