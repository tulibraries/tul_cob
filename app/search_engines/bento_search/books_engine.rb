# frozen_string_literal: true

module BentoSearch
  class BooksEngine < BlacklightEngine
    def search_implementation(args)
      query = args.fetch(:query, "")
      per_page = args.fetch(:per_page)
      query = { q: query, per_page: per_page, f: { format: ["Book"] } }

      response = search_results(query, &proc_availability_facet_only).first
      results(response)
    end
  end
end
