# frozen_string_literal: true

class LibGuidesController < ApplicationController
  def index
    @guides = LibGuidesApi.fetch(params[:q]).as_json
    render layout: false
  end
end
