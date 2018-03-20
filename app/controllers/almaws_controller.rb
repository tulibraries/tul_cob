class AlmawsController < ApplicationController
  layout false

  def item
    mms_id = params[:mms_id]
    @items = Alma::BibItems.find(mms_id)
  end
end
