# frozen_string_literal: true

class QueryListController < ApplicationController
  def show
    search_service = search_service_class.new(config: blacklight_config, user_params: params)
    (resp, _) = search_service.search_results

    @docs = resp.dig("response", "docs") || []
    @footer_field = params["footer_field"]
    render layout: false
  end
end
