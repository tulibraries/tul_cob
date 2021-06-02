# frozen_string_literal: true

class QueryListsController < ApplicationController
  def index
    respond_to do |format|
      format.turbo_stream { render layout: false }
    end
  end
end
