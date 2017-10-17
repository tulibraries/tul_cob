# frozen_string_literal: true

module BlacklightAlmaHelper
  include BlacklightAlma::HelperBehavior

  def alma_service_type_for_fulfillment_url(document)
    if (document["format"] || "").first.casecmp("electronic").zero?
      "viewit"
    else
      "getit"
    end
  end
end
