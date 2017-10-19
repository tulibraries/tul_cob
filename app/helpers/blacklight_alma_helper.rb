module BlacklightAlmaHelper

  include BlacklightAlma::HelperBehavior

  def alma_service_type_for_fulfillment_url(document)
    return false if document['availability_facet'].nil?
    if document['availability_facet'].include?("Online")
      'viewit'
    else
      'getit'
    end
  end
end
