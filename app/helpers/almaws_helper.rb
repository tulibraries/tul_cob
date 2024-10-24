# frozen_string_literal: true

module AlmawsHelper
  include Blacklight::CatalogHelperBehavior

  def hold_allowed_partial(request_options, document)
    if request_options.hold_allowed? && non_asrs_items.present?
      render partial: "hold_allowed", locals: { request_options:, document: }
    end
  end

  def asrs_allowed_partial(request_options, document)
    if request_options.hold_allowed? && available_asrs_items.present?
      render partial: "asrs_allowed", locals: { request_options:, document: }
    end
  end

  def digitization_allowed_partial(request_options, document)
    if request_options.digitization_allowed?
      render partial: "digitization_allowed", locals: { request_options:, document: }
    end
  end

  def booking_allowed_partial(request_options, document)
    if request_options.booking_allowed?
      render partial: "booking_allowed", locals: { request_options:, document: }
    end
  end

  def resource_sharing_broker_allowed_partial(request_options, books, document)
    if request_options.resource_sharing_broker_allowed? && books.present?
      render partial: "resource_sharing_broker_allowed", locals: { request_options:, books:, document: }
    end
  end

  def aeon_request_partial(request_options, document)
    if aeon_request_allowed(document).present?
      render partial: "aeon_allowed", locals: { request_options:, document: }
    end
  end

  def digital_copy_partial(request_options, document)
    if digital_help_allowed?(document)
      render partial: "digital_copy_help", locals: { request_options:, document: }
    end
  end

  def open_shelves_partial(request_options, document)
    if open_shelves_allowed?(document)
      render partial: "open_shelves", locals: { request_options:, document: }
    end
  end

  def equipment_partial(request_options, document, equipment)
    if equipment.present?
      render partial: "equipment", locals: { request_options:, document:, equipment: }
    end
  end

  def no_temple_request_options_available(request_options, books, document, equipment)
    if !@request_options.hold_allowed? &&
      !@request_options.digitization_allowed? &&
      !@request_options.booking_allowed? &&
      !aeon_request_allowed(document) &&
      !digital_copy_partial(request_options, document) &&
      !open_shelves_partial(request_options, document) &&
      equipment.empty?
      render partial: "no_request_options", locals: { request_options:, books:, document:, equipment: } unless @request_options.resource_sharing_broker_allowed?
    end
  end

  def relevant_request_options(request_options, books, document, equipment)
    [ request_options.hold_allowed? && non_asrs_items.present?,
      request_options.hold_allowed? && available_asrs_items.present?,
      request_options.digitization_allowed?,
      request_options.booking_allowed?,
      request_options.resource_sharing_broker_allowed? && books.present?,
      aeon_request_allowed(document),
      digital_help_allowed?(document),
      open_shelves_allowed?(document),
      equipment.present?]
  end

  def only_one_option_allowed(request_options, books, document, equipment)
    relevant_request_options(request_options, books, document, equipment).select(&:itself).count == 1
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
    asrs_items(items).select { |item|
      if item.physical_material_type["value"] == "DVD"
        item
      else
        item.in_place?
      end
    }
  end
end
