# frozen_string_literal: true

module ElectronicResourceHelper
  def has_one_electronic_resource?(document)
    document.fetch("electronic_resource_display", []).length == 1
  end

  def has_many_electronic_resources?(document)
    electronic_resources = document.fetch("electronic_resource_display", [])
    electronic_resources.length > 1 ||
      has_one_electronic_resource?(document) &&
      render_electronic_notes(electronic_resources.first).present?
  end

  def check_for_full_http_link(args)
    [args[:document][args[:field]]].flatten.compact.map { |field|
      if field["url"].present?
        electronic_access_links(field)
      else
        electronic_resource_link_builder(field)
      end
    }.join("").html_safe
  end

  def electronic_access_links(field)
    text = field.fetch("title", "Link to Resource").sub(/ *[ ,.\/;:] *\Z/, "")
    url = field["url"]
    content_tag(:div, link_to(text, url, title: "Target opens in new window", target: "_blank"), class: "electronic_links online-list-items")
  end

  def electronic_resource_link_builder(field)
    return if field.empty?
    return if field["availability"] == "Not Available"

    title = field.fetch("title", "Find it online")
    electronic_notes = render_electronic_notes(field)

    item_html =
      if field["coverage_statement"].present?
        [render_alma_eresource_link(field["portfolio_id"], field["coverage_statement"]), title]
          .select(&:present?).join(" - ")
      else
        [render_alma_eresource_link(field["portfolio_id"], title), field["coverage_statement"]]
          .select(&:present?).join(" - ")
      end
    item_html = [item_html, electronic_notes]
      .select(&:present?).join(" ").html_safe

    content_tag(:div, item_html , class: " electronic_links online-list-item")
  end

  def single_link_builder(field)
    if field["url"].present?
      field["url"]
    else
      alma_electronic_resource_direct_link(field["portfolio_id"])
    end
  end

  def render_alma_eresource_link(portfolio_pid, db_name)
    link_to(db_name, alma_electronic_resource_direct_link(portfolio_pid), title: "Target opens in new window", target: "_blank")
  end

  def alma_electronic_resource_direct_link(portfolio_pid)
    query = {
        "u.ignore_date_coverage": "true",
        "Force_direct": true,
        portfolio_pid:
    }
    alma_build_openurl(query)
  end

  def alma_domain
    Rails.configuration.alma["delivery_domain"]
  end

  def alma_institution_code
    Rails.configuration.alma["institution_code"]
  end

  def alma_build_openurl(query)
    query_defaults = {
      rfr_id: "info:sid/primo.exlibrisgroup.com",
    }

    URI::HTTPS.build(
      host: alma_domain,
      path: "/view/uresolver/#{alma_institution_code}/openurl",
      query: query_defaults.merge(query).to_query).to_s
  end

  def electronic_notes(type)
    name = "#{type}_notes"

    Rails.cache.fetch(name) do
      JsonStore.find_by(name:)&.value || {}
    end
  end

  def service_unavailable_fields
    [ "service_temporarily_unavailable", "service_unavailable_date", "service_unavailable_reason" ]
  end

  def get_collection_notes(id)
    (electronic_notes("collection")[id] || {})
      .except(*service_unavailable_fields)
      .values.select(&:present?)
  end

  def get_service_notes(id)
    (electronic_notes("service")[id] || {})
      .except(*service_unavailable_fields)
      .values.select(&:present?)
  end

  def get_unavailable_notes(id)
    (electronic_notes("service")[id] || {})
      .slice("service_unavailable_reason")
      .select { |k, v| v.present? }.values
      .map { |reason| "This service is temporarily unavailable due to: #{reason}." }
  end

  def render_electronic_notes(field)
    collection_id = field["collection_id"]
    service_id = field["service_id"]

    public_notes = field["public_note"]
    authentication_notes = field["authentication_note"]
    collection_notes = get_collection_notes(collection_id)
    service_notes = get_service_notes(service_id)
    unavailable_notes = get_unavailable_notes(service_id)

    if collection_notes.present? ||
        service_notes.present? ||
        public_notes.present? ||
        authentication_notes.present? ||
        unavailable_notes.present?

      render partial: "electronic_notes", locals: {
        collection_notes:,
        service_notes:,
        public_notes:,
        authentication_notes:,
        unavailable_notes:,
      }
    end
  end
end
