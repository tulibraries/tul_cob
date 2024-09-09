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

    @items = get_bib_items(@mms_id)
    availability = @items.group_by { |item| item["item_data"]["pid"] }
        .transform_values { |item| AlmawsAvailability.new(item.first).to_h }
    @document.merge_item_data!(availability)
    @document_availability = @document.document_items_grouped

    @request_data = RequestData.new(@items)
    @pickup_locations = @request_data.pickup_location_codes.join(",")
    @request_level = @request_data.get_request_level
    @redirect_to = params[:redirect_to]
    render layout: false
  end

  def request_options
    @mms_id = params[:mms_id]
    @user_id = current_user.uid

    _, @document = begin search_service.fetch(@mms_id) rescue [ nil, SolrDocument.new({}) ] end
    @items = get_bib_items(@mms_id)
    @request_data = RequestData.new(@items, params)

    # Information about document and bib items for request modal
    @books = @document.fetch("format") if @document["format"]&.include?("Book")
    @author = @document.fetch("creator_display", []).first || ""
    @description = @request_data.material_types_and_descriptions
    @asrs_description = @request_data.asrs_material_types_and_descriptions
    @material_types = @request_data.material_types

    # Pickup locations
    @pickup_locations = @request_data.pickup_locations
    @asrs_pickup_locations = @request_data.asrs_pickup_locations
    @item_level_locations = @request_data.item_level_locations
    @equipment = @request_data.equipment_locations
    @booking_location = @request_data.booking_locations

    # Request levels
    @request_level = @request_data.request_level
    @asrs_request_level = @request_data.asrs_request_level

    # Request options
    if [@request_level, @asrs_request_level].include?("item")
      @request_options = get_item_request_options(@mms_id, @user_id, @request_data.item_holding_ids)
      # If nil, recheck using different id hash (should be reviewed at some point)
      if @request_options&.request_options.nil?
        @request_options = get_item_request_options(@mms_id, @user_id, @request_data.item_holding_ids_backup)
      end
    else
      @request_options = get_bib_request_options(@mms_id, @user_id)
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
      response = do_with_json_logger(log) { Alma::BibRequest.submit(bib_options) }
      confirmation = RequestConfirmation.new(response, params[:hold_pickup_location])
      flash["notice"] = confirmation.message
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
        response = do_with_json_logger(log) { Alma::BibRequest.submit(options) }
        requests_made += 1
      else
        params["available_asrs_items"]
          .select { |item| item["description"] == options[:description] }
          .each do |item|

          holding_id = item["holding_id"]
          item_pid = item["item_pid"]

          item_options = { holding_id:, item_pid: }

          response = do_with_json_logger(log.merge(item_options)) {
            Alma::ItemRequest.submit(options.merge(item_options))
          }

          requests_made += 1
          break
        end
      end

      if requests_made > 0
        confirmation = RequestConfirmation.new(response, params[:asrs_pickup_location])
        flash["notice"] = confirmation.message
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
      response = do_with_json_logger(log) { Alma::BibRequest.submit(bib_options) }
      confirmation = RequestConfirmation.new(response)
      flash["notice"] = confirmation.message
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
      response = do_with_json_logger(log) { Alma::BibRequest.submit(bib_options) }
      confirmation = RequestConfirmation.new(response)
      flash["notice"] = confirmation.message
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

    def get_bib_request_options(mms_id, user_id)
      log = { type: "bib_request_options", user: user_id }
      response = do_with_json_logger(log) { Alma::RequestOptions.get(mms_id, user_id:) }
    end

    def get_item_request_options(mms_id, user_id, holdings)
      holdings.map { |holding_id, item_pid|
        log = { type: "item_request_options", mms_id:, holding_id:, item_pid:, user: user_id }
        do_with_json_logger(log) { Alma::ItemRequestOptions.get(mms_id, holding_id, item_pid, user_id:) }
      }
        .reduce do |acc, request|
          options = acc.request_options || []
          next_options = request.request_options || []
          acc.request_options = options + next_options
          acc
        end
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
