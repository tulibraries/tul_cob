# frozen_string_literal: true

module AlmawsHelper
  include Blacklight::CatalogHelperBehavior

  def hold_allowed_partial(request_options)
    if request_options.hold_allowed?
      render partial: "hold_allowed", locals: { request_options: request_options }
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
      resource_sharing_broker_allowed_partial(request_options, books)
    end
  end
end
