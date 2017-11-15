# frozen_string_literal: true

module BlacklightAlmaHelper
  include BlacklightAlma::HelperBehavior

  # Overrides
  # BlacklightAlma::HelperBehavior#alma_service_type_for_fulfillment_url.  Bib
  # records may have both physical and electronic holdings: This guarantees
  # that we always "viewit" in the case of an "Online" record.
  def alma_service_type_for_fulfillment_url(document = {})
    document ||= {}
    if document.fetch("availability_facet", []).include?("At the Library")
      "getit"
    else
      "viewit"
    end
  end

  def alma_app_fulfillment_url(document, service_type: nil, language: nil, view: nil)
      mms_id = document.respond_to?(:alma_mms_id) ? document.alma_mms_id : document.id
      service_type ||= alma_service_type_for_fulfillment_url(document)

      query = {
          'is_new_ui': true,
          "req.skin": "temple_01",
          svc_dat: service_type,
          'rft.mms_id': mms_id,
      }
      rft_dat_value = [language.present? ? "language=#{language}" : nil,
                       view.present? ? "view=#{view}" : nil].compact.join(',')
      query['rft_dat'] = rft_dat_value if rft_dat_value.present?
      query['u.ignore_date_coverage'] = 'true' if service_type == 'viewit'

      if session[:alma_auth_type] == 'sso' && session[:alma_sso_token].present?
        query['sso'] = 'true'
        query['token'] = session[:alma_sso_token]
      elsif session[:alma_social_login_provider].present?
        query['oauth'] = 'true'
        query['provider'] = session[:alma_social_login_provider]
      end

      alma_build_openurl(query)
  end
end
