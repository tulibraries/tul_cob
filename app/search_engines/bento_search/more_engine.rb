# frozen_string_literal: true

module BentoSearch
  class MoreEngine < BlacklightEngine
    def search_implementation(args)
      query = args.fetch(:query, "")
      query = { q: query, per_page: 2 }

      response = search_results(query).first

      item = BentoSearch::ResultItem.new(custom_data: response)

      results(response).append(item)
    end
  end
end
