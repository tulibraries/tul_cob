# frozen_string_literal: true

module LibwizardHelper
  def build_libwizard_url(document)
    doc_params = openurl_libwizard_params(document)
    URI::HTTPS.build(host: "temple.libwizard.com",
      path: "/f/LibrarySearchRequest", query: doc_params.to_query).to_s
  end

  def build_guest_login_libwizard_url(document)
    doc_params = openurl_libwizard_params(document).slice("rft.title", "rft.date", "edition", "rft_id")
    URI::HTTPS.build(host: "temple.libwizard.com",
      path: "/f/ContinueAsGuest", query: doc_params.to_query).to_s
  end

  def build_error_libwizard_url(document)
    doc_params = openurl_libwizard_params(document)
    URI::HTTPS.build(host: "temple.libwizard.com",
      path: "/f/LibrarySearchError", query: doc_params.to_query).to_s
  end

  def openurl_libwizard_params(document)
    decorated_doc = DocumentDecorator.new(document)
    doc_params =
    {
      "rft.title" => decorated_doc.field_joiner(:title_statement_display),
      "rft.date" => decorated_doc.field_joiner(:pub_date),
      "edition" => decorated_doc.field_joiner(:edition_display),
      "rft.isbn" => decorated_doc.field_joiner(:isbn_display),
      "rft.issn" => decorated_doc.field_joiner(:issn_display),
      "rft.oclcnum" => decorated_doc.field_joiner(:oclc_display),
      "rft.pub" => [
        decorated_doc.field_joiner(:imprint_display),
        decorated_doc.field_joiner(:imprint_prod_display),
        decorated_doc.field_joiner(:imprint_dist_display),
        decorated_doc.field_joiner(:imprint_man_display),
      ].select(&:present?).join(", "),
    }
    if document.id.present?
      doc_params["rft_id"] = url_for([document, only_path: false])
    end
    doc_params.select { |k, v| v.present? }
  end

  def libwizard_tutorial?
    ::FeatureFlags.libwizard_tutorial?(params)
  end
end
