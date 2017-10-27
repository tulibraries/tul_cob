# frozen_string_literal: true

module BlacklightAlmaHelper
  include BlacklightAlma::HelperBehavior

  # Overrides
  # BlacklightAlma::HelperBehavior#alma_service_type_for_fulfillment_url.  Bib
  # records may have both physical and electronic holdings: This guarantees
  # that we always "viewit" in the case of an "Online" record.
  def alma_service_type_for_fulfillment_url(document = {})
    document ||= {}
    if document.fetch("availability_facet", []).include?("Online")
      "viewit"
    else
      "getit"
    end
  end
end
