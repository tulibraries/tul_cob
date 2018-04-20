# frozen_string_literal: true

module BentoSearch
  class BooksEngine < BlacklightEngine
    def search_implementation(args)
      query = args.fetch(:query, "")
      query = { q: query, f: { format: ["Book"] } }

      results = BentoSearch::Results.new

      solr_result = search_results(query, &proc_remove_facets).first.response
      results.total_items = solr_result["numFound"]

      solr_result["docs"].each do |item|
        results << conform_to_bento_result(item)
      end

      results
    end
  end
end
