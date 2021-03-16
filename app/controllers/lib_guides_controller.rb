# frozen_string_literal: true

class LibGuidesController < ApplicationController
  def index
    # The derived_lib_guides_search_term helper method generates the query term.
    @guides = LibGuidesApi.fetch(params["q"]).as_json

    respond_to do |format|
      format.html { render layout: false }
      format.json do
        render plain: @guides.to_json, status: 200, content_type: "application/json"
      end
    end
  end
end
