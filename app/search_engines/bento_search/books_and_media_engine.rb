# frozen_string_literal: true

module BentoSearch
  class BooksAndMediaEngine < BlacklightEngine
    def search_implementation(args)
      query = args.fetch(:query, "")

      user_params = { q: query, per_page: 3 }
      config = blacklight_config
      search_service = search_service_class.new(config:, user_params:)

      (response, _) = search_service.search_results(&processor_chain)

      item = BentoSearch::ResultItem.new(custom_data: response)

      results(response).append(item)
    end

    def processor_chain
      Proc.new { |builder|
        processor_chain = [ :availability_facet_only,
                            :filter_suppressed,
                            :with_format_facet ]
        builder.append(*processor_chain)
      }
    end

    def view_link(total = nil, helper)
      url = url(helper)
      link_text = Flipflop.style_updates? ? "See all #{total} results" : "View all #{total} results"
      helper.link_to link_text, url, class: "bento-full-results"
    end
  end
end
