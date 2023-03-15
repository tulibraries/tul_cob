# frozen_string_literal: true

module BentoSearch
  class LibGuidesEngine < BlacklightEngine
    def search_implementation(args)
      bento_results = BentoSearch::Results.new
      guides_response = []

      path = "http://lgapi-us.libapps.com/1.1/guides/"
      query = args[:query].gsub(" ", "+")
      query_params = {
        site_id: 17,
        search_terms: query, status: 1,
        sort_by: "relevance",
        expand: "owner",
        guide_types: "1,2,3,4",
        key: ENV["LIB_GUIDES_API_KEY"] }.to_param
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
      bento_results.total_items = 0

      bento_results
    end

    def view_link(total = nil, helper)
      url = "https://guides.temple.edu/"
      helper.link_to("View all research guide results", url, target: "_blank")
    end
  end
end
