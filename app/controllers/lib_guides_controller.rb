# frozen_string_literal: true

class LibGuidesController < ApplicationController
  before_action :permit_lib_guides_parameters, only: :index

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

  private

    def params
      @permitted_lib_guides_params || super
    end
    public :params

    def permit_lib_guides_parameters
      @permitted_lib_guides_params = params.permit(:q, :format)
    end
end
