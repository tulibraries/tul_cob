# frozen_string_literal: true

class AlmawsController < ApplicationController
  layout false

  def item
    mms_id = params[:mms_id]
    @items = Alma::BibItem.find(mms_id, limit: 100)
      .filter_missing_and_lost
      .grouped_by_library
  end
end
