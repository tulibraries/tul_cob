# frozen_string_literal: true

module AlmawsHelper
  include Blacklight::CatalogHelperBehavior

  def booking_allowed_partial(request_options)
    if request_options.booking_allowed?
      render partial: "booking_allowed", locals: { request_options: request_options }
    end
  end

  def only_one_option_allowed(request_options)
    [ request_options.hold_allowed?,
     request_options.digitization_allowed?,
     request_options.booking_allowed? ]
    .select(&:itself).count == 1
  end
end
