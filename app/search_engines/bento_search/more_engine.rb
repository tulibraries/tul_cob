# frozen_string_literal: true

module BentoSearch
  class MoreEngine < BlacklightEngine
    def search_implementation(args)
      query = args.fetch(:query, "")

      user_params = { q: query, per_page: 2 }
      config = blacklight_config
      search_service = search_service_class.new(config: config, user_params: user_params)

      (response, _) = search_service.search_results(&proc_minus_books_journals)

      item = BentoSearch::ResultItem.new(custom_data: response)

      results(response).append(item)
    end

    def proc_minus_books_journals
      Proc.new { |builder|
        processor_chain = [ :no_books_or_journals ]
        builder.append(*processor_chain)
      }
    end
  end
end
