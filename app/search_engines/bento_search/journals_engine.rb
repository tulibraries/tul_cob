# frozen_string_literal: true

module BentoSearch
  class JournalsEngine < BlacklightEngine
    def search_implementation(args)
      query = args.fetch(:query, "")

      results = BentoSearch::Results.new
      solr_result = search_results(q: query, f: { format: ["Journal/Periodical"] })
      results.total_items = solr_result["numFound"]

      solr_result["docs"].each do |item|
        results << conform_to_bento_result(item)
      end

      results
    end
  end
end
