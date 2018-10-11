# frozen_string_literal: true

module BentoSearch
  class PrimoEngine < BlacklightEngine
    delegate :blacklight_config, to: PrimoCentralController

    def search_implementation(args)
      # Avoid making a costly call for no reason.
      if !args.present?
        response = { "docs" => [] }
      else
        response = search_results(args).first
      end

      results(response)
    end

    def conform_to_bento_result(item)
      BentoSearch::ResultItem.new(
        title: item["title"],
        authors: item.fetch("creator", []).map { |author| BentoSearch::Author.new(display: author.tr(";", " ")) },
        publisher: item.fetch("isPartOf", "None found"),
        link: Rails.application.routes.url_helpers.primo_central_document_url(item["pnxId"], only_path: true),
        custom_data: item)
    end

    def url(helper)
      helper.search_path(helper.params.except(:controller, :action))
    end

    def view_link(total = nil, helper)
      url = url(helper)
      helper.link_to "View all #{total} articles", url, class: "full-results"
    end
  end
end
