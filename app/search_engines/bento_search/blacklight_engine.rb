# frozen_string_literal: true

module BentoSearch
  class BlacklightEngine
    include BentoSearch::SearchEngine
    include Blacklight::SearchHelper

    delegate :blacklight_config, to: CatalogController

    def search_implementation(args)
      query = args.fetch(:query, "")

      results = BentoSearch::Results.new
      solr_result = search_results(q: query, &proc_remove_facets).first.response

      results.total_items = solr_result["numFound"]

      solr_result["docs"].each do |item|
        results << conform_to_bento_result(item)
      end

      results
    end

    def proc_remove_facets
      Proc.new { |builder|
        processor_chain = [ :add_query_to_solr, :remove_facets ]
        builder.except(builder.default_processor_chain)
          .append(*processor_chain)
      }
    end

    def conform_to_bento_result(item)
      BentoSearch::ResultItem.new(title: item.fetch("title_statement_display", []).first,
        authors: item.fetch("creator_display", []).map { |author| BentoSearch::Author.new(display: author) },
        publisher: item.fetch("imprint_display", []).join(" "),
        link: Rails.application.routes.url_helpers.solr_document_url(item["id"], only_path: true))
    end
  end
end
