# frozen_string_literal: true

class AlmawsController < ApplicationController
  layout false

  before_action :authenticate_user!, except: [:item]

  def item
    @mms_id = params[:mms_id]
    start = Time.now
    bib_items = Alma::BibItem.find(@mms_id, limit: 100)
    json_request_logger(type: "bib_items_availability", uri: bib_items.request.uri.to_s, start: start)
    @items = bib_items.filter_missing_and_lost.grouped_by_library
    @pickup_locations = CobAlma::Requests.valid_pickup_locations(@items).join(",")
    @request_level = has_desc?(bib_items) ? "item" : "bib"
    @redirect_to = params[:redirect_to]
  end

  def request_options
    @mms_id = params[:mms_id]
    @items = Alma::BibItem.find(@mms_id, limit: 100)
    @holding_id = CobAlma::Requests.item_holding_id(@items)
    @item_pid = CobAlma::Requests.item_pid(@items)
    @author = @items.map { |item| item["bib_data"]["author"].to_s }.first
    @description = CobAlma::Requests.descriptions(@items)
    @equipment = CobAlma::Requests.equipment(@items)
    @booking_location = CobAlma::Requests.booking_location(@items)
    @material_types = CobAlma::Requests.physical_material_type(@items)
    @pickup_locations = params[:pickup_location].split(",").collect { |lib| { lib => helpers.library_name_from_short_code(lib) } }
    @user_id = current_user.uid
    @request_level = params[:request_level]
    start = Time.now
    if @request_level == "item"
      @request_options = Alma::ItemRequestOptions.get(@mms_id, @holding_id, @item_pid, user_id: @user_id)
      json_request_logger(type: "item_request_options", start: start, mms_id: @mms_id, holding_id: @holding_id, item_pid: @item_pid, user: current_user.id)
    else
      @request_options = Alma::RequestOptions.get(@mms_id, user_id: @user_id)
      json_request_logger(type: "bib_request_options", start: start, user: current_user.id)
    end
  end

  def send_hold_request
    date = date_or_nil(params[:last_interest_date])
    bib_options = {
    mms_id: params[:mms_id],
    user_id: current_user.uid,
    description: params[:description],
    pickup_location_library: params[:pickup_location],
    pickup_location_type: "LIBRARY",
    request_type: "HOLD",
    last_interest_date: date,
    comment: params[:comment]
    }
    @request_level = params[:request_level]
    start = Time.now
    request = Alma::BibRequest.submit(bib_options)
    json_request_logger({ type: "submit_hold_request", start: start, user: current_user.id }.merge(bib_options))

    if request.success?
      flash["success"] = "Your request has been submitted."
      redirect_back(fallback_location: root_path)
    elsif request.raw_response.dig("errorList", "error")
      flash["notice"] = "There was an error processing your request. Contact a librarian for help."
      redirect_back(fallback_location: root_path)
    end
  end

  def send_booking_request
    start_date = date_or_nil(params[:booking_start_date])
    end_date = date_or_nil(params[:booking_end_date])
    bib_options = {
    mms_id: params[:mms_id],
    user_id: current_user.uid,
    pickup_location_library: params[:pickup_location],
    pickup_location_type: "LIBRARY",
    material_type: params[:material_type],
    request_type: "BOOKING",
    booking_start_date: start_date,
    booking_end_date: end_date,
    description: params[:description],
    comment: params[:comment]
    }

    start = Time.now
    request = Alma::BibRequest.submit(bib_options)
    json_request_logger({ type: "submit_booking_request", start: start, user: current_user.id }.merge(bib_options))

    if request.success?
      flash[:success] = "Your request has been submitted."
      redirect_back(fallback_location: root_path)
    elsif request.raw_response.dig("errorList", "error")
      error = request.raw_response.dig("errorList", "error").map { |e| e.values }
      if error.flatten.include?("401136")
        flash["notice"] = "This item is already booked for those dates."
        redirect_back(fallback_location: root_path)
      end
    else
      flash["notice"] = "There was an error processing your request. Contact a librarian for help."
      redirect_back(fallback_location: root_path)
    end
  end

  def send_digitization_request
    date = date_or_nil(params[:last_interest_date])
    partial = params[:partial_or_full] == "true" ? true : false
    bib_options = {
    mms_id: params[:mms_id],
    user_id: current_user.uid,
    description: params[:description],
    chapter_or_article_title: params[:chapter_or_article_title],
    chapter_or_article_author: params[:chapter_or_article_author],
    request_type: "DIGITIZATION",
    target_destination: { value: "DIGI_DEPT_INST" },
    partial_digitization: partial,
    last_interest_date: date,
    comment: params[:comment]
    }

    @request_level = params[:request_level]

    start = Time.now
    request = Alma::BibRequest.submit(bib_options)
    json_request_logger({ type: "submit_digitization_request", start: start, user: current_user.id }.merge(bib_options))

    if request.success?
      flash[:success] = "Your request has been submitted."
      redirect_back(fallback_location: root_path)
    elsif request.raw_response.dig("errorList", "error")
      flash["notice"] = "There was an error processing your request. Contact a librarian for help."
      redirect_back(fallback_location: root_path)
    end
  end

  private

    def has_desc?(items)
      item_levels = items.map { |item| item["item_data"]["description"] }.reject(&:blank?)
      item_levels.present?
    end

    def date_or_nil(param)
      begin
        date = Date.strptime(param, "%Y-%m-%d")
      rescue
        date = nil
      end
      date
    end
end
