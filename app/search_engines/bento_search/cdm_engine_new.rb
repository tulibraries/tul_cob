# frozen_string_literal: true

module BentoSearch
  class CDMEngine
    # include BentoSearch::SearchEngine

    delegate :blacklight_config, to: ::SearchController

    def new(args)
      query = args.fetch(:query, "").gsub("/", " ")
      query = ERB::Util.url_encode(query)
      fields = args.fetch(:cdm_fields)
      format = args.fetch(:cdm_format)
      cdm_url = "https://digital.library.temple.edu/digital/bl/dmwebservices/index.php?q=dmQuery/all/CISOSEARCHALL^#{query}^all^and/#{fields}/sortby/3/#{format}"
      results = []
      response = []

      begin
        response = JSON.load(URI.open(cdm_url))
        total_items = response.dig("results", "pager", "total") || 0
        response["records"].each do |i|
          item.title = i.fetch("title")
          item.abstract = i.fetch("date")
          item.link = "https://digital.library.temple.edu/digital/collection#{i["collection"]}/id/#{i["pointer"]}"
          item.other_links = ["https://digital.library.temple.edu/digital/api/singleitem/image/#{i["collection"]}/#{i["pointer"]}/default.jpg",
                              "https://digital.library.temple.edu/digital/utils/ajaxhelper/?CISOROOT=#{i["collection"]}&CISOPTR=#{i["pointer"]}&action=2&DMSCALE=6&DMHEIGHT=340"]
          results << item
        end
      rescue StandardError => e
        results.total_items = 0
        Honeybadger.notify("Ran into error while try to process CDM: #{e.message}")
      end
      results
    end


    def url(helper)
      query = helper.params.slice(:q)
      "https://digital.library.temple.edu/digital/search/searchterm/#{query}/order/nosort"
    end

    def view_link(total = nil, helper)
      url = url(helper)
      helper.link_to "View all digital collection results", url, class: "bento-full-results"
    end
  end
end
