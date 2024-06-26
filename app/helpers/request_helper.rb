# frozen_string_literal: true

module RequestHelper
  include Blacklight::CatalogHelperBehavior

  def request_modal(mms_id, pickup_locations, request_level, request_page_type)
    link_to(t("requests.request_button"), "#", id: "request-btn-#{mms_id}", class: "btn request-btn #{request_page_type}-request-btn", data: { "blacklight-modal": "trigger", "action": "availability#modal show#loading", "availability-target": "href", "show-target": "href" })
  end

  def request_redirect_url(mms_id)
    url = direct_request_options_url(mms_id:)
    new_user_session_with_redirect_path(url)
  end

  def ez_borrow_link_title(url)
    uri = URI.parse(url)
    params = CGI.parse(uri.query)

    URI::HTTPS.build(
      host: uri.host,
      path: "/Search/Results",
      query: URI.encode_www_form({
        "lookfor" => params["rft.title"],
        "type" => "Title"
      })).to_s
  end

  def modal_exit_button_name(make_modal_link)
    name = raw("&times;")

    if make_modal_link
      render_nav_link(:search_catalog_path, name)
    else
      name
    end
  end

  def aeon_request_url(document)
    form_fields = {
         ItemTitle: document.fetch("title_statement_display", ""),
         ItemPlace: document.fetch("imprint_display", ""),
         ReferenceNumber: document.fetch("mms_id_display", ""),
         CallNumber: document.fetch("call_number_display", ""),
         ItemAuthor: document.fetch("creator_display", ""),
         "rft.pages": document["collection_area_display"]
     }

    openurl_field_values = form_fields.map { |k, v|
      [k, v.to_s.delete('[]""')] }.to_h

    openurl_field_values["Action"] = 10
    openurl_field_values["Form"] = 30


    URI::HTTPS.build(
      host:  "temple.aeon.atlas-sys.com",
      path: "/Logon/",
      query: openurl_field_values.to_query).to_s
  end

  def aeon_request_allowed(document)
    document_items = document.fetch("items_json_display", [])
    libraries = document_items.collect { |item| library(item) }
    libraries.include?("SCRC")
  end

  def aeon_request_button(document)
    document_items = document.fetch("items_json_display", [])
    libraries = document_items.collect { |item| library(item) }

    if libraries.include?("SCRC")
      button_to(t("requests.aeon_button_text"), aeon_request_url(document), class: "btn btn-primary")
    end
  end
end
