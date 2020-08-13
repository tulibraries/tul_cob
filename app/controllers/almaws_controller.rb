# frozen_string_literal: true

# This controller is implemented to get information about a document's
# availability because the alma api is currently too slow to load this at the
# document level.
class AlmawsController < CatalogController
  layout proc { |controller| false if request.xhr? }

  before_action :authenticate_user!, except: [:item]

  rescue_from Alma::BibItemSet::ResponseError,
    with: :offset_too_large

  def item
    @mms_id = params[:mms_id]
    _, @document = begin search_service.fetch(params[:doc_id]) rescue [ nil, SolrDocument.new({}) ] end
    # TODO: refactor to repository/response/search_behavior ala primo/solr.
    page = (params[:page] || 1).to_i
    limit = (params[:limit] || 100).to_i
    offset = (limit * page) - limit

    log = { type: "bib_items_availability" }
    bib_items = do_with_json_logger(log) { Alma::BibItem.find(@mms_id, limit: limit, offset: offset, expand: "due_date") }
    @response = Blacklight::Alma::Response.new(bib_items, params)
    @items = bib_items.filter_missing_and_lost.grouped_by_library
    availability = bib_items.group_by { |item| item["item_data"]["pid"] }.
                     transform_values { |item|
      { availability: helpers.availability_status(item.first) } }
    @document.merge_item_data!(availability)
    @document_availability = helpers.document_availability_info(@document)
    @pickup_locations = CobAlma::Requests.valid_pickup_locations(@items).join(",")
    # Defined here as a parameter for the route
    @request_level = get_request_level(bib_items)
    @redirect_to = params[:redirect_to]
    render layout: false
  end

  def request_options
    @mms_id = params[:mms_id]
    _, @document = begin search_service.fetch(@mms_id) rescue [ nil, SolrDocument.new({}) ] end
    log = { type: "alma_bib_item", mms_id: @mms_id }
    @items = do_with_json_logger(log) { Alma::BibItem.find(@mms_id, limit: 100) }.filter_missing_and_lost
    @books = CobAlma::Requests.physical_material_type(@items).collect { |item| item["value"] if item["value"].include?("BOOK") }.compact
    @author = @items.map { |item| item["bib_data"]["author"].to_s }.first
    @description = CobAlma::Requests.descriptions(@items)
    @item_level_locations = CobAlma::Requests.item_level_locations(@items)
    @equipment = CobAlma::Requests.equipment(@items)
    @booking_location = CobAlma::Requests.booking_location(@items)
    @material_types = CobAlma::Requests.physical_material_type(@items).compact
    pickup_locations = params[:pickup_location]&.split(",") ||
      CobAlma::Requests.valid_pickup_locations(@items.grouped_by_library)

    @pickup_locations = pickup_locations.collect { |lib| { lib => helpers.library_name_from_short_code(lib) } }
    @asrs_pickup_locations = CobAlma::Requests.asrs_pickup_locations.collect { |lib| { lib => helpers.library_name_from_short_code(lib) } }
    @user_id = current_user.uid
    @request_level = params[:request_level] ||
      get_request_level(@items)

    @asrs_request_level = get_request_level(@items, "asrs")

    if @asrs_request_level == "item"
      @asrs_description =  CobAlma::Requests.asrs_descriptions(@items)
    else
      @asrs_description = @description || @asrs_description = ""
    end

    if @request_level == "item" || @asrs_request_level == "item"
      @item_level_holdings = CobAlma::Requests.item_holding_ids(@items)
      @second_attempt_holdings = CobAlma::Requests.second_attempt_item_holding_ids(@items)
      @request_options = get_largest_request_options_set(@item_level_holdings)

      if @request_options&.request_options.nil?
        @request_options = get_largest_request_options_set(@second_attempt_holdings)
      end
    else
      log = { type: "bib_request_options", user: current_user.id }
      @request_options = do_with_json_logger(log) { Alma::RequestOptions.get(@mms_id, user_id: @user_id) }
    end

    # Define when we want modal exit button to be a link.
    @make_modal_link = params[:pickup_locations].blank? &&
      params[:request_level].blank?
  end

  def send_hold_request
    date = date_or_nil(params[:hold_last_interest_date])
    bib_options = {
    mms_id: params[:mms_id],
    user_id: current_user.uid,
    description: params[:hold_description],
    pickup_location_library: params[:hold_pickup_location],
    pickup_location_type: "LIBRARY",
    material_type: { value: params[:material_type] },
    request_type: "HOLD",
    last_interest_date: date,
    comment: params[:hold_comment]
    }
    @request_level = params[:request_level]
    log = { type: "submit_hold_request", user: current_user.id }.merge(bib_options)

    begin
      do_with_json_logger(log) { Alma::BibRequest.submit(bib_options) }
      flash["notice"] = helpers.successful_request_message
      redirect_back(fallback_location: root_path)
    rescue
      flash["notice"] = "There was an error processing your request. Contact a librarian for help."
      redirect_back(fallback_location: root_path)
    end
  end

  def send_asrs_request
    date = date_or_nil(params[:asrs_last_interest_date])
    options = {
    mms_id: params[:mms_id],
    user_id: current_user.uid,
    description: params[:asrs_description],
    pickup_location_library: params[:asrs_pickup_location],
    pickup_location_type: "LIBRARY",
    material_type: { value: params[:material_type] },
    request_type: "HOLD",
    last_interest_date: date,
    comment: params[:asrs_comment]
    }

    @asrs_request_level = params[:asrs_request_level]
    log = { type: "submit_asrs_request", user: current_user.id }.merge(options)

    begin
      requests_made = 0
      if @asrs_request_level == "bib"
        do_with_json_logger(log) { Alma::BibRequest.submit(options) }
        requests_made += 1
      else
        # TODO: Will update this depending on Justin's decision regarding
        # multiple requests on same item.
        params["available_asrs_items"]
          .select { |item| item["description"] == options[:description] }
          .each do |item|

          holding_id = item["holding_id"]
          item_pid = item["item_pid"]

          item_options = { holding_id: holding_id, item_pid: item_pid }

          do_with_json_logger(log.merge(item_options)) {
            Alma::ItemRequest.submit(options.merge(item_options))
          }

          requests_made += 1
          break
        end
      end

      if requests_made > 0
        flash["notice"] = helpers.successful_request_message
      else
        flash["notice"] = "There was an error processing your request. Contact a librarian for help."
      end


      redirect_back(fallback_location: root_path)

    rescue
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
    pickup_location_library: params[:booking_pickup_location],
    pickup_location_type: "LIBRARY",
    material_type: { value: params[:material_type] },
    request_type: "BOOKING",
    booking_start_date: start_date,
    booking_end_date: end_date,
    description: params[:booking_description],
    comment: params[:booking_comment]
    }

    log = { type: "submit_booking_request", user: current_user.id }.merge(bib_options)
    begin
      do_with_json_logger(log) { Alma::BibRequest.submit(bib_options) }
      flash["notice"] = helpers.successful_request_message
      redirect_back(fallback_location: root_path)
    rescue Alma::BibRequest::ItemAlreadyExists
      flash["notice"] = "This item is already booked for those dates."
      redirect_back(fallback_location: root_path)
    rescue
      flash["notice"] = "There was an error processing your request. Contact a librarian for help."
      redirect_back(fallback_location: root_path)
    end
  end

  def send_digitization_request
    date = date_or_nil(params[:digitization_last_interest_date])
    bib_options = {
      mms_id: params[:mms_id],
      user_id: current_user.uid,
      description: params[:digitization_description],
      chapter_or_article_title: params[:chapter_or_article_title],
      chapter_or_article_author: params[:chapter_or_article_author],
      request_type: "DIGITIZATION",
      target_destination: { value: "DIGI_DEPT_INST" },
      partial_digitization: true,
      last_interest_date: date,
      comment: [params[:digitization_comment], "Title: #{params[:chapter_or_article_title]}", "Author: #{params[:chapter_or_article_author]}", "From page: #{params[:from_page]}", "To page: #{params[:to_page]}"].compact.join("\n"),
      required_pages_range: [{
        from_page: params[:from_page], to_page: params[:to_page]
      }]
    }

    @request_level = params[:request_level]

    log = { type: "submit_digitization_request", user: current_user.id }.merge(bib_options)
    begin
      do_with_json_logger(log) { Alma::BibRequest.submit(bib_options) }
      flash["notice"] = helpers.successful_request_message
      redirect_back(fallback_location: root_path)
    rescue
      flash["notice"] = "There was an error processing your request. Contact a librarian for help."
      redirect_back(fallback_location: root_path)
    end
  end

  def offset_too_large
    render html: "<p class='m-2'>Please contact the library service desk for additional assistance.</p>".html_safe
  end

  private

    def get_request_level(items, partial = nil)
      if partial == "asrs"
        if helpers.asrs_items(items).present? && helpers.non_asrs_items(items).present?
          "item"
        else
          has_desc?(items) ? "item" : "bib"
        end
      else
        has_desc?(items) ? "item" : "bib"
      end
    end

    def get_largest_request_options_set(items)
      items.map { |holding_id, item_pid|
        log = { type: "item_request_options", mms_id: @mms_id, holding_id: holding_id, item_pid: item_pid, user: current_user.id }
        do_with_json_logger(log) { Alma::ItemRequestOptions.get(@mms_id, holding_id, item_pid, user_id: @user_id) }
      }
        .sort_by { |r| r.request_options&.count || 0 }
        .last
    end

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
