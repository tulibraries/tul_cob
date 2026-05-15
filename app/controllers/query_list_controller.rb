# frozen_string_literal: true

class QueryListController < ApplicationController

  include Blacklight::Searchable

  caches_action :show, expires_in: 1.hours, cache_path: Proc.new { |c| c.request.url }

  def show
    (resp, _) = search_service.search_results

    @docs = resp.docs
    @footer_field = params["footer_field"]
    render layout: false
  end
end
