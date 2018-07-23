# frozen_string_literal: true

module BentoSearch
  class BooksEngine < BlacklightEngine
    def search_implementation(args)
      query = args.fetch(:query, "")
      per_page = args.fetch(:per_page)
      query = { q: query, per_page: per_page, f: { format: ["Book"] } }

      response = search_results(query, &proc_availability_facet_only).first
      results(response)
    end

    def url(helper)
      params = helper.params
      helper.search_catalog_path(q: params[:q], f: { format: ["Book"] })
    end

    def view_link(total = nil, helper)
      url = url(helper)
      helper.link_to "View all #{total} books", url, class: "full-results"
    end
  end
end
