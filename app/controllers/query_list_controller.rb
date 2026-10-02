# frozen_string_literal: true

class QueryListController < ApplicationController
  include Blacklight::Searchable
  include PermittedSearchParams

  caches_action :show, expires_in: 1.hours, cache_path: Proc.new { |c| c.request.url }
  prepend_before_action :permit_query_list_search_parameters, only: :show

  def show
    resp = search_service.search_results

    @docs = resp.docs
    @footer_field = params["footer_field"]
    render layout: false
  end

  private

    def permit_query_list_search_parameters
      unless blacklight_config.search_state_fields.include?(:footer_field)
        blacklight_config.search_state_fields += [ :footer_field ]
      end
      permit_search_parameters
    end
end
