# frozen_string_literal: true

module RequestHelper
  include Blacklight::CatalogHelperBehavior

  def request_modal(mms_id, pickup_locations, request_level)
    link_to(t("requests.request_button"), "#", id: "request-btn-#{mms_id}", class: "btn btn-sm btn-primary request-button float-right #{params[:action] == 'search-results-request-btn' ? 'search-results-request-btn' : 'record-page-request-btn'}", data: { "blacklight-modal": "trigger", "action": "availability#modal", "target": "availability.href" })
  end

  def ez_borrow_link_with_updated_query(url)
    uri = URI.parse(url)
    params = CGI.parse(uri.query)
    new_params = params.select { |key, value| ["group", "LS", "dest", "PI", "RK", "rft.title"].include? key }

    URI::HTTPS.build(
      host: uri.host,
      path: uri.path,
      query: URI.encode_www_form(new_params)).to_s
  end

  def successful_request_message
    t("requests.success_message_html", href: link_to(t("requests.success_message_href"), users_account_path))
  end
end
