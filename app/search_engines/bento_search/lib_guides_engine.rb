# frozen_string_literal: true

module BentoSearch
  class LibGuidesEngine < BlacklightEngine
    def search_implementation(args)
      bento_results = BentoSearch::Results.new
      guides_response = []

      config = Rails.configuration.x.apis[:lib_guides] || {}
      path = config[:base_url].presence || "https://lgapi-us.libapps.com/1.1/guides"
      query = args[:query].gsub(" ", "+")
      query_config = config[:query] || {}
      query_params = {
        site_id: config[:site_id].presence || 17,
        search_terms: query,
        status: query_config[:status].presence || 1,
        sort_by: query_config[:sort_by].presence || "relevance",
        expand: query_config[:expand].presence || "owner",
        guide_types: query_config[:guide_types].presence || "1,2,3,4",
        key: config[:api_key].presence || "LIB_GUIDES_API_KEY",
      }.to_param
      guides_url = path + "?" + query_params
      guides_response = JSON.load(URI.open(guides_url))

      results = guides_response[0, 3]

      results.each do |i|
        item = BentoSearch::ResultItem.new
        item.title = i["name"]
        if i["description"].present?
          item.abstract = i["description"]
        end
        item.link = i["url"]
        bento_results << item
      end

      bento_results
    end

    def url(helper)
      path = "https://guides.temple.edu/srch.php?"
      params = helper.params.slice(:q)
      path + params.to_query
    end

    def view_link(total = nil, helper)
      url = url(helper)
      link_text = Flipflop.style_updates? ? "See all results" : "View all results"
      helper.link_to link_text, url, class: "bento-full-results bento_lib_guides_header"
    end
  end
end
