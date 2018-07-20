# frozen_string_literal: true

module BentoSearch
  class JournalsEngine < BlacklightEngine
    def search_implementation(args)
      query = args.fetch(:query, "")
      per_page = args.fetch(:per_page)

      query = { q: query, per_page: per_page, f: { format: ["Journal/Periodical"] } }

      response = search_results(query, &proc_availability_facet_only).first
      results(response)
    end

    def url(helper)
      params = helper.params
      helper.search_catalog_path(q: params[:q], f: { format: ["Journal/Periodical"] })
    end

    def view_link(total = nil, helper)
      url = url(helper)
      helper.link_to "View all #{total} journals", url, class: "full-results"
    end
  end
end
