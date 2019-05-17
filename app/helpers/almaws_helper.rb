# frozen_string_literal: true

module AlmawsHelper
  include Blacklight::CatalogHelperBehavior

  def hold_allowed_partial(request_options)
    if request_options.hold_allowed? && non_asrs_items.present?
      render partial: "hold_allowed", locals: { request_options: request_options }
    end
  end

  def asrs_allowed_partial(request_options)
    if request_options.hold_allowed? && asrs_items.present?
      render partial: "asrs_allowed", locals: { request_options: request_options }
    end
  end

  def digitization_allowed_partial(request_options)
    if request_options.digitization_allowed?
      render partial: "digitization_allowed", locals: { request_options: request_options }
    end
  end

  def booking_allowed_partial(request_options)
    if request_options.booking_allowed?
      render partial: "booking_allowed", locals: { request_options: request_options }
    end
  end

  def resource_sharing_broker_allowed_partial(request_options, books)
    if request_options.resource_sharing_broker_allowed? && books.present?
      render partial: "resource_sharing_broker_allowed", locals: { request_options: request_options, books: books }
    end
  end

  def no_temple_request_options_available(request_options, books)
    if !@request_options.hold_allowed? && !@request_options.digitization_allowed? && !@request_options.booking_allowed?
      render partial: "no_request_options", locals: { request_options: request_options, books: books } unless @request_options.resource_sharing_broker_allowed?
    end
  end

  def only_one_option_allowed(request_options)
    [ request_options.hold_allowed?,
     request_options.digitization_allowed?,
     request_options.booking_allowed?, request_options.resource_sharing_broker_allowed? ]
    .select(&:itself).count == 1
  end

  def non_asrs_items(items = @items)
    items.select { |item| !is_asrs_item?(item) }
  end

  def asrs_items(items = @items)
    items.select { |item| is_asrs_item?(item) }
  end

  def is_asrs_item?(item)
    item.library == "ASRS"
  end

  def available_asrs_items(items = @items)
    # Alma bug: item.item_data["requested"] is true for all items on bib level requests.
    asrs_items.select { |item| item.in_place?  }
  end
end
