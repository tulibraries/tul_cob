# frozen_string_literal: true

module BentoSearch
  class BlacklightEngine
    include BentoSearch::SearchEngine
    include Blacklight::SearchHelper

    delegate :blacklight_config, to: CatalogController

    def search_implementation(args)
      query = args.fetch(:query, "")

      results = BentoSearch::Results.new
      response = search_results(q: query, &proc_availability_facet_only).first
      results(response)
    end

    def proc_availability_facet_only
      Proc.new { |builder|
        builder.append(:availability_facet_only)
      }
    end

    def results(response)
      results = BentoSearch::Results.new
      availability_facet =
        response.facet_counts&.dig("facet_fields", "availability_facet")
        .to_a.each_slice(2).to_h

      response = response["response"]

      results.total_items = {
        query_total: response["numFound"],
        online_total: availability_facet["Online"]
      }

      response["docs"].each do |doc|
        results << conform_to_bento_result(doc)
      end

      results
    end

    def conform_to_bento_result(item)
      BentoSearch::ResultItem.new(title: item.fetch("title_statement_display", []).first,
        authors: item.fetch("creator_display", []).map { |author| BentoSearch::Author.new(display: author.tr("|", " ")) },
        publisher: item.fetch("imprint_display", []).join(" "),
        link: Rails.application.routes.url_helpers.solr_document_url(item["id"], only_path: true),
        custom_data: SolrDocument.new(item))
    end

    def url(helper)
      helper.search_catalog_path(q: helper.params[:q])
    end

    def view_link(total = nil, helper)
      url = url(helper)
      helper.link_to "View all catalog results", url, class: "full-results"
    end
  end
end
