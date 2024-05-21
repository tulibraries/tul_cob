# frozen_string_literal: true

class AlmawsController < CatalogController
  layout proc { |controller| false if request.xhr? }

  before_action :authenticate_user!, except: [:item]
  before_action :xhr!, only: [:item, :request_options]

  rescue_from Alma::BibItemSet::ResponseError,
    with: :offset_too_large

  def item
    @mms_id = params[:mms_id]
    _, @document = begin search_service.fetch(params[:doc_id]) rescue [ nil, SolrDocument.new({}) ] end

    response = get_bib_items(@mms_id)
    availability = response.group_by { |item| item["item_data"]["pid"] }
        .transform_values { |item| { availability: helpers.availability_status(item.first) } }
    @document.merge_item_data!(availability)
    @document_availability = helpers.document_availability_info(@document)

    @items = response.group_by(&:library)
    @pickup_locations = CobAlma::Requests.valid_pickup_locations(@items).join(",")
    @request_level = get_request_level(response)
    @redirect_to = params[:redirect_to]
    render layout: false
  end

  def request_options
    @mms_id = params[:mms_id]
    _, @document = begin search_service.fetch(@mms_id) rescue [ nil, SolrDocument.new({}) ] end

    @items = get_bib_items(@mms_id)

    @books = @document.fetch("format") if @document["format"]&.include?("Book")
    @author = @document.fetch("creator_display", []).first || ""
    @description = CobAlma::Requests.physical_material_type_and_descriptions(@items)
    @material_types = CobAlma::Requests.physical_material_type(@items).compact
    @equipment = CobAlma::Requests.equipment(@items)

    pickup_locations = params[:pickup_location]&.split(",") || []
    @pickup_locations = pickup_locations.collect { |lib| { lib => helpers.library_name_from_short_code(lib) } }
    @asrs_pickup_locations = CobAlma::Requests.asrs_pickup_locations.collect { |lib| { lib => helpers.library_name_from_short_code(lib) } }
    @item_level_locations = CobAlma::Requests.item_level_locations(@items)
    @booking_location = CobAlma::Requests.booking_location(@items)

    @user_id = current_user.uid
    @request_level = params[:request_level] || "bib"
    @asrs_request_level = get_request_level(@items, "asrs")

    if @asrs_request_level == "item"
      @asrs_description =  CobAlma::Requests.material_type_and_asrs_descriptions(@items)
    else
      @asrs_description = @description || ""
    end

    if @request_level == "item" || @asrs_request_level == "item"
      @item_level_holdings = CobAlma::Requests.item_holding_ids(@items)
      @request_options = get_request_options_set(@item_level_holdings)

      if @request_options&.request_options.nil?
        @second_attempt_holdings = CobAlma::Requests.second_attempt_item_holding_ids(@items)
        @request_options = get_request_options_set(@second_attempt_holdings)
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
    bib_options = {
    mms_id: params[:mms_id],
    user_id: current_user.uid,
    description: params[:hold_description],
    pickup_location_library: params[:hold_pickup_location],
    pickup_location_type: "LIBRARY",
    material_type: { value: params[:material_type] },
    request_type: "HOLD",
    comment: params[:hold_comment]
    }
    @request_level = params[:request_level]
    log = { type: "submit_hold_request", user: current_user.id }.merge(bib_options)

    begin
      do_with_json_logger(log) { Alma::BibRequest.submit(bib_options) }
      flash["notice"] = helpers.successful_request_message
      redirect_back(fallback_location: root_path)
    rescue => e
      Honeybadger.notify(e.message + " " + log.to_s)
      flash["notice"] = "There was an error processing your request. Contact Temple University Libraries for help."
      redirect_back(fallback_location: root_path)
    end
  end

  def send_asrs_request
    options = {
    mms_id: params[:mms_id],
    user_id: current_user.uid,
    description: params[:asrs_description],
    pickup_location_library: params[:asrs_pickup_location],
    pickup_location_type: "LIBRARY",
    material_type: { value: params[:material_type] },
    request_type: "HOLD",
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
        params["available_asrs_items"]
          .select { |item| item["description"] == options[:description] }
          .each do |item|

          holding_id = item["holding_id"]
          item_pid = item["item_pid"]

          item_options = { holding_id:, item_pid: }

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
        flash["notice"] = "There was an error processing your request. Contact Temple University Libraries for help."
      end

      redirect_back(fallback_location: root_path)

    rescue => e
      Honeybadger.notify(e.message + " " + log.to_s)
      flash["notice"] = "There was an error processing your request. Contact Temple University Libraries for help."
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
      flash["notice"] = "There was an error processing your request. Contact Temple University Libraries for help."
      redirect_back(fallback_location: root_path)
    end
  end

  def send_digitization_request
    bib_options = {
      mms_id: params[:mms_id],
      user_id: current_user.uid,
      description: params[:digitization_description],
      chapter_or_article_title: params[:chapter_or_article_title],
      chapter_or_article_author: params[:chapter_or_article_author],
      request_type: "DIGITIZATION",
      target_destination: { value: "DIGI_DEPT_INST" },
      partial_digitization: true,
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
      flash["notice"] = "There was an error processing your request. Contact Temple University Libraries for help."
      redirect_back(fallback_location: root_path)
    end
  end

  def offset_too_large
    render html: "<p class='m-2'>Availability information can not be loaded. Contact a librarian for help.</p>".html_safe, status: :bad_gateway
  end

  private

    def get_bib_items(mms_id)
      Rails.cache.fetch("#{mms_id}/bib_items", expires_in: 30.seconds) do
        log = { type: "bib_items_availability" }
        response = do_with_json_logger(log) { Alma::BibItem.find(mms_id, limit: 100, offset: 0, expand: "due_date").all }.to_a.reject(&:missing_or_lost?)
      end
    end

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

    # Makes an ItemsRequestOption request per item and collapses
    # all the results into one request option set.
    def get_request_options_set(items)
      items.map { |holding_id, item_pid|
        log = { type: "item_request_options", mms_id: @mms_id, holding_id:, item_pid:, user: current_user.id }
        do_with_json_logger(log) { Alma::ItemRequestOptions.get(@mms_id, holding_id, item_pid, user_id: @user_id) }
      }
        .reduce do |acc, request|
          options = acc.request_options || []
          next_options = request.request_options || []

          acc.request_options = options + next_options
          acc
        end
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
