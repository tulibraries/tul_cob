# frozen_string_literal: true

require "spec_helper"

class LibGuidesController < ApplicationController
  def index
    render json: LibGuidesApi.fetch(params[:q])
  end
end
