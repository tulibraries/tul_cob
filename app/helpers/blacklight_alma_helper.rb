module BlacklightAlmaHelper

  include BlacklightAlma::HelperBehavior

def alma_service_type_for_fulfillment_url(document)
  if (document['format'] || '').first.downcase == 'electronic'
    'viewit'
  else
    'getit'
  end
end

end
