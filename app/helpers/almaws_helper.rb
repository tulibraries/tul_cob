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

  def only_one_option_allowed(request_options)
    options = []
    hold_request = "hold" if request_options.hold_allowed?
    digitization_request = "digitization" if request_options.digitization_allowed?
    booking_request = "booking" if request_options.booking_allowed?
    options << hold_request << digitization_request << booking_request

    return true if options.compact.uniq.length == 1
  end
end
