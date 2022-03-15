# frozen_string_literal: true

module BentoSearch
  class PrimoEngine < BlacklightEngine
    delegate :blacklight_config, :search_service_class, to: PrimoCentralController

    def search_implementation(args)
      query = args.fetch(:query, "")
      per_page = args.fetch(:per_page)

      user_params = { q: query, per_page: per_page }.with_indifferent_access
      config = blacklight_config
      search_service = search_service_class.new(config: config, user_params: user_params)

      (response, _) = search_service.search_results
      results(response)
    end

    def conform_to_bento_result(item)
      BentoSearch::ResultItem.new(
        title: item["title"],
        authors: item.fetch("creator", []).map { |author| BentoSearch::Author.new(display: author.tr(";", " ")) },
        publisher: item.fetch("isPartOf", "None found"),
        link: doc_link(item["pnxId"]),
        custom_data: item)
    end

    def doc_link(id)
      Rails.application.routes.url_helpers.article_document_path(id)
    end

    def url(helper)
      params = helper.params.slice(:q)
        .merge(action: :index, controller: :primo_central)
      helper.url_for(params)
    end

    def view_link(total = nil, helper)
      url = url(helper)
      helper.link_to "View all #{total} articles", url, class: "bento-full-results"
    end
  end
end
