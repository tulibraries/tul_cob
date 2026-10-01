# frozen_string_literal: true

class QueryListController < ApplicationController
  include Blacklight::Searchable
  include PermittedSearchParams

  caches_action :show, expires_in: 1.hours, cache_path: Proc.new { |c| c.request.url }
  prepend_before_action :permit_search_parameters, only: :show

  def show
    resp = search_service.search_results

    @docs = resp.docs
    @footer_field = params["footer_field"]
    render layout: false
  end

  private

    def search_parameter_extra_keys
      %w[footer_field]
    end
end
