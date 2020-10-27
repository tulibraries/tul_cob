# frozen_string_literal: true

class LibGuidesController < ApplicationController
  def index
    @guides = LibGuidesApi.fetch(params[:q]).as_json

    respond_to do |format|
      format.html { render layout: false }
      format.json do
        render plain: @guides, status: 200, content_type: "application/json"
      end
    end
  end
end
