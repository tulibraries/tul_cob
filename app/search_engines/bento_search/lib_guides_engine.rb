# frozen_string_literal: true

module BentoSearch
  class LibGuidesEngine < BlacklightEngine
    def search_implementation(args)
      bento_results = BentoSearch::Results.new
      guides_response = []
      guides_response = LibGuidesApi.fetch(args[:query]).as_json

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
