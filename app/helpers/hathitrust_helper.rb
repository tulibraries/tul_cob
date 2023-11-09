# frozen_string_literal: true

module HathitrustHelper
  def build_hathitrust_url(field)
    record_id = field.fetch("bib_key", nil)
    return if record_id.nil?
    URI::HTTPS.build(host: "catalog.hathitrust.org",
      path: "/Record/#{record_id}",
      query: "signon=swle:https://fim.temple.edu/idp/shibboleth"
    ).to_s
  end

  def render_hathitrust_link(ht_bib_key_field)
    render "catalog/hathitrust_link", ht_bib_key_field: ht_bib_key_field
  end

  def hathitrust_link_allowed?(document)
    ht_bib_key_field = document.fetch("hathi_trust_bib_key_display", []).first rescue nil
    ht_bib_key_field.fetch("access", "deny") == "allow" rescue nil
  end

  def render_hathitrust_display(document)
    ht_bib_key_field = document.fetch("hathi_trust_bib_key_display", []).first rescue nil
    return if ht_bib_key_field.nil?
    online_resources = []
    online_resources << render_hathitrust_link(ht_bib_key_field)

    if (campus_closed? || hathitrust_link_allowed?(document))
      render "catalog/online_availability", online_resources: online_resources
    end
  end

  def render_hathitrust_button(document)
    ht_bib_key_field = document.fetch("hathi_trust_bib_key_display", []).first rescue nil
    return if ht_bib_key_field.nil?
    link = render_hathitrust_link(ht_bib_key_field)

    if (campus_closed? || hathitrust_link_allowed?(document))
      render "catalog/hathitrust_button", document: document, links: link
    end
  end
end
