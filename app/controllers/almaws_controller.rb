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
    @pickup_locations = params[:pickup_location].split(",").collect { |lib| { lib => helpers.library_name_from_short_code(lib) } }
    @user_id = current_user.uid
    @request_level = params[:request_level]
    if @request_level == "item"
      @request_options = Alma::ItemRequestOptions.get(@mms_id, @holding_id, @item_pid, user_id: @user_id)
    else
      @request_options = Alma::RequestOptions.get(@mms_id, user_id: @user_id)
    end
    end

  def send_hold_request
    not_needed_date = DateTime.new(params[:last_interest_date]["year"].to_i, params[:last_interest_date]["month"].to_i, params[:last_interest_date]["day"].to_i)
    # TODO: Add pickup location information
    bib_options = {
    mms_id: params[:mms_id],
    user_id: current_user.uid,
    description: params[:description],
    pickup_location_library: params[:pickup_location],
    pickup_location_type: "LIBRARY",
    request_type: "HOLD",
    last_interest_date: not_needed_date,
    comment: params[:comment]
    }

    item_options = {
      mms_id: params[:mms_id],
      user_id: current_user.uid,
      description: params[:description],
      pickup_location_library: params[:pickup_location],
      pickup_location_type: "LIBRARY",
      request_type: "HOLD",
      last_interest_date: not_needed_date,
      comment: params[:comment],

      holding_id: params[:holding_id],
      item_pid: params[:item_pid],
    }
    @request_level = params[:request_level]
    if @request_level == "bib"
      request = Alma::BibRequest.submit(bib_options)
    else
      request = Alma::ItemRequest.submit(item_options)
    end

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
    chapter_or_article_title: params[:chapter_or_article_title],
    chapter_or_article_author: params[:chapter_or_article_author],
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

  # def bib_or_item_request
  #   @request_level = params[:request_level]
  #   if @request_level == "bib"
  #     request = Alma::BibRequest.submit(options)
  #   else
  #     request = Alma::ItemRequest.submit(options)
  #   end
  #
  #   if request.success?
  #     flash[:success] = "Your request has been submitted."
  #     redirect_back(fallback_location: root_path)
  #   end
  # end
end
