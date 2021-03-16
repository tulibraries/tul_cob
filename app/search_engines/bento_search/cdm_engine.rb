# frozen_string_literal: true

module BentoSearch
  class CDMEngine
    include BentoSearch::SearchEngine

    delegate :blacklight_config, to: ::SearchController

    def search_implementation(args)
      query = args.fetch(:query, "").gsub("/", " ")
      query = ERB::Util.url_encode(query)
      results = BentoSearch::Results.new
      response = {}

      begin
        response = CDM::find(query)
        results.total_items = response.dig("results", "pager", "total") || 0
      rescue StandardError => e
        results.total_items = 0
        Honeybadger.notify("Ran into error while try to process CDM: #{e.message}")
      end

      results << BentoSearch::ResultItem.new(custom_data: response)
      results
    end
  end
end
