# frozen_string_literal: true

module BentoSearch
  class BooksAndMediaEngine < BlacklightEngine
    def search_implementation(args)
      query = args.fetch(:query, "")

      user_params = { q: query, per_page: 3 }
      config = blacklight_config
      search_service = search_service_class.new(config: config, user_params: user_params)

      (response, _) = search_service.search_results(&proc_minus_journals)

      item = BentoSearch::ResultItem.new(custom_data: response)

      results(response).append(item)
    end

    def proc_minus_journals
      Proc.new { |builder|
        processor_chain = [ :no_journals ]
        builder.append(*processor_chain)
      }
    end

    def view_link(total = nil, helper)
      url = url(helper)
      helper.link_to "View all #{total} records", url, class: "full-results"
    end
  end
end
