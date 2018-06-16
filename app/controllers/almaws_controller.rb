# frozen_string_literal: true

class AlmawsController < ApplicationController
  layout false

  def item
    mms_id = params[:mms_id]
    start = Time.now
    bib_items = Alma::BibItem.find(mms_id, limit: 100)
    elapsed = Time.now - start
    logger.info JSON.dump(
      type: "bib_items_availability",
       uri: bib_items.request.uri.to_s,
       took: elapsed
      )
    @items = bib_items.filter_missing_and_lost.grouped_by_library
  end
end
