# frozen_string_literal: true

module AlmawsHelper
  include Blacklight::CatalogHelperBehavior

  def only_one_option_allowed(request_options)
    [ request_options.hold_allowed?,
     request_options.digitization_allowed?,
     request_options.booking_allowed? ]
    .select(&:itself).count == 1
  end
end
