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
    doc_params =
    {
      "rft.title" => doc_field_joiner(document, :title_statement_display),
      "rft.date" => doc_field_joiner(document, :pub_date),
      "edition" => doc_field_joiner(document, :edition_display),
      "rft.isbn" => doc_field_joiner(document, :isbn_display),
      "rft.issn" => doc_field_joiner(document, :issn_display),
      "rft.oclcnum" => doc_field_joiner(document, :oclc_display),
      "rft.pub" => [
        doc_field_joiner(document, :imprint_display),
        doc_field_joiner(document, :imprint_prod_display),
        doc_field_joiner(document, :imprint_dist_display),
        doc_field_joiner(document, :imprint_man_display),
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
