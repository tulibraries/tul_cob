# frozen_string_literal: true

module BentoSearch
  class LibGuidesEngine < BlacklightEngine
    def search_implementation(args)
      bento_results = BentoSearch::Results.new
      guides_response = []

<<<<<<< BL-1905-Upgrade_to_LibGuides_API_1.2
      token = access_token
      return bento_results if token.blank?

      path = "https://lgapi-us.libapps.com/1.2/guides"
=======
      config = Rails.configuration.apis.dig(:lib_guides) || {}
      path = config[:base_url].presence || "https://lgapi-us.libapps.com/1.1/guides"
>>>>>>> main
      query = args[:query].gsub(" ", "+")
      query_config = config[:query] || {}
      query_params = {
<<<<<<< BL-1905-Upgrade_to_LibGuides_API_1.2
        site_id: ENV["LIB_GUIDES_SITE_ID"],
        search_terms: query,
        status: 1,
        sort_by: "relevance",
        expand: "owner",
        guide_types: "1,2,3,4"
      }.to_param

      response = HTTParty.get(
        "#{path}?#{query_params}",
        headers: { "Authorization" => "Bearer #{token}" }
      )

      guides_response = response.success? ? JSON.parse(response.body) : []
=======
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
>>>>>>> main

      results = guides_response[0, 3]

      results.each do |i|
        item = BentoSearch::ResultItem.new
        item.title = i["name"]
        item.abstract = i["description"] if i["description"].present?
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

    private

      def access_token
        response = HTTParty.post(
          "https://lgapi-us.libapps.com/1.2/oauth/token",
          body: {
            client_id: ENV["LIB_GUIDES_CLIENT_ID"],
            client_secret: ENV["LIB_GUIDES_CLIENT_SECRET"],
            grant_type: "client_credentials"
          }
        )
        return nil unless response.success?

        JSON.parse(response.body)["access_token"]
      rescue => e
        Honeybadger.notify("Fetching LibGuides OAuth token failed with #{e}")
        nil
      end
  end
end
