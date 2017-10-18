module BlacklightAlmaHelper

  include BlacklightAlma::HelperBehavior

  def alma_service_type_for_fulfillment_url(document)
    if document['availability_facet'].include?("Online")
      output = 'viewit'
    else
      output = 'getit'
    end
  end
end
