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
    @pickup_locations = CobAlma::Requests.valid_pickup_locations(@items).join(",")
    @request_level = has_desc?(bib_items) ? "item" : "bib"
  end

  def request_options
    @mms_id = params[:mms_id]
    @items = Alma::BibItem.find(@mms_id, limit: 100)
    @holding_id = CobAlma::Requests.item_holding_id(@items)
    @item_pid = CobAlma::Requests.item_pid(@items)
    @author = @items.map { |item| item["bib_data"]["author"].to_s }.first
    @description = CobAlma::Requests.descriptions(@items)
    @pickup_locations = params[:pickup_locations].split(",").map { |location| helpers.library_name_from_short_code(location) }
    @user_id = current_user.uid
    @request_level = params[:request_level]
    if @request_level == "item"
      @request_options = Alma::ItemRequestOptions.get(@mms_id, @holding_id, @item_pid, user_id: @user_id)
    else
      @request_options = Alma::RequestOptions.get(@mms_id, user_id: @user_id)
    end
  end

  def send_hold_request
    # TODO: Add pickup location information
    options = {
    mms_id: params[:mms_id],
    user_id: current_user.uid,
    request_type: "HOLD",
    last_interest_date: not_needed_date,
    comment: params[:comment]
    }
    request = Alma::BibRequest.submit(options)

    if request.success?
      flash[:success] = "Your request has been submitted."
      redirect_back(fallback_location: root_path)
    end
  end

  def send_digitization_request
    not_needed_date = DateTime.new(params[:last_interest_date]["year"].to_i, params[:last_interest_date]["month"].to_i, params[:last_interest_date]["day"].to_i)
    partial = params[:partial_or_full] == "true" ? true : false
    options = {
    mms_id: params[:mms_id],
    user_id: current_user.uid,
    holding_id: params[:holding_id],
    item_pid: params[:item_pid],
    description: params[:description],
    request_type: "DIGITIZATION",
    target_destination: { value: "DIGI_DEPT_INST" },
    partial_digitization: partial,
    last_interest_date: not_needed_date,
    comment: params[:comment]
    }
    @request_level = params[:request_level]
    if @request_level == "bib"
      request = Alma::BibRequest.submit(options)
    else
      request = Alma::ItemRequest.submit(options)
    end

    if request.success?
      flash[:success] = "Your request has been submitted."
      redirect_back(fallback_location: root_path)
    end
  end

  def has_desc?(items)
    item_levels = items.map { |item| item["item_data"]["description"] }.reject(&:blank?)
    item_levels.present?
  end
end
