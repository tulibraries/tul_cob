# frozen_string_literal: true

class AlmawsController < ApplicationController
  layout false

  def item
    @mms_id = params[:mms_id]
    start = Time.now
    bib_items = Alma::BibItem.find(@mms_id, limit: 100)
    elapsed = Time.now - start
    logger.info JSON.dump(
      type: "bib_items_availability",
       uri: bib_items.request.uri.to_s,
       took: elapsed
      )
    @items = bib_items.filter_missing_and_lost.grouped_by_library
    @pickup_locations = Alma::Requests.valid_pickup_locations(@items).join(",")
  end

  def request_options
    mms_id = params[:mms_id]
    @pickup_locations = params[:pickup_locations].split(",").map {|location| helpers.library_name_from_short_code(location)}
    #@description = params[:descriptions].split(",").map {|desc| helpers.description(desc)}
    user_id = current_user.uid
    @request_options = Alma::RequestOptions.get(mms_id, user_id: user_id)
  end
end
