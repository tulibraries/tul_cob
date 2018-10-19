# frozen_string_literal: true

module BentoSearch
  class PrimoEngine < BlacklightEngine
    delegate :blacklight_config, to: PrimoCentralController

    def search_implementation(args)
      query = args.fetch(:query, "")
      per_page = args.fetch(:per_page)

      # Avoid making a costly call for no reason.
      if query.empty?
        response = { "docs" => [] }
      else
        response = search_results(q: query, per_page: per_page).first
      end

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
      Rails.application.routes.url_helpers.primo_central_document_path(id)
    end

    def url(helper)
      params = helper.params
      helper.url_for(action: :index, controller: :primo_central, q: params[:q])
    end

    def view_link(total = nil, helper)
      url = url(helper)
      helper.link_to "View all #{total} articles", url, class: "full-results"
    end
  end
end
