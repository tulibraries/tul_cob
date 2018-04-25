# frozen_string_literal: true

module BentoSearch
  class PrimoEngine < BlacklightEngine
    delegate :blacklight_config, to: PrimoCentralController

    def search_implementation(args)
      query = args.fetch(:query, "")

      # Avoid making a costly call for no reason.
      if query.empty?
        response = { "docs" => [] }
      else
        response = search_results(q: query).first["response"]
      end

      results(response)
    end

    def conform_to_bento_result(item)
      BentoSearch::ResultItem.new(
        title: item["title"],
        authors: item.fetch("creator", []).map { |author| BentoSearch::Author.new(display: author) },
        publisher: item.fetch("isPartOf", "Non found"),
        link: Rails.application.routes.url_helpers.primo_central_document_url(item["pnxId"], only_path: true))
    end
  end
end
