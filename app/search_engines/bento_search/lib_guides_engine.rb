# frozen_string_literal: true

module BentoSearch
  class LibGuidesEngine < BlacklightEngine
    def search_implementation(args)
      bento_results = BentoSearch::Results.new
      guides_response = []

      path = IntegrationConfig.lib_guides_base_url
      query = args[:query].gsub(" ", "+")
      query_params = {
        site_id: IntegrationConfig.lib_guides_site_id,
        search_terms: query, status: 1,
        sort_by: "relevance",
        expand: "owner",
        guide_types: "1,2,3,4",
        key: IntegrationConfig.lib_guides_api_key }.to_param
      guides_url = "#{path.chomp("/")}?#{query_params}"
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
