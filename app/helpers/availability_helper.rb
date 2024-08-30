# frozen_string_literal: true

module AvailabilityHelper
  include Blacklight::CatalogHelperBehavior
  include UsersHelper

  PHYSICAL_TYPE_EXCLUSIONS = /BOOK|ISSUE|SCORE|KIT|MAP|ISSBD|GOVRECORD|OTHER/i

  def render_availability(doc)
    if index_fields(doc).fetch("availability", nil)
      render "index_availability_section", document: doc
    end
  end

  def render_alma_availability(document)
    # We are checking index_fields["bound_with_ids"] because that is a field that is unique to catalog records
    # We do not want this to render if the item is from Primo, etc.
    if index_fields["bound_with_ids"] && document.alma_availability_mms_ids.present?
      content_tag :dl, nil, class: "d-flex flex-row document-metadata blacklight-availability availability-ajax-load my-0", "data-availability-ids": document.alma_availability_mms_ids.join(",")
    end
  end

  def render_online_availability(doc_presenter)
    field = blacklight_config.show_fields["electronic_resource_display"]
    return if field.nil?

    online_resources = [doc_presenter.field_value(field)]
      .select { |r| !r.empty? }.compact

    if !online_resources.empty?
      render "online_availability", online_resources:
    end
  end

  def render_online_availability_button(doc)
    links = check_for_full_http_link(document: doc, field: "electronic_resource_display")

    if !links.empty?
      render "online_availability_button", document: doc, links:
    end
  end

  def availability_alert(document)
    # nil is returned in cases where document has no items_json_display field.
    # Use double bang to force coerce nils to false.
    !!document["items_json_display"]&.map { |item|
      item["availability"].blank?
    }&.any?
  end

  def scrc_instructions(key, document)
    if key == "Special Collections Research Center"
      render partial: "scrc_instructions", locals: { key:, document: }
    end
  end

  def material_type(item)
    return unless item["material_type"].present?

    type = item["material_type"]

    if !type.match(PHYSICAL_TYPE_EXCLUSIONS)
      return Rails.configuration.material_types[type]
    end
  end

  def public_note(item)
    item["description"] ? "; " : ""
    item["public_note"] ? "Note: #{item['public_note']}" : ""
  end

  def summary_list(items)
    summary_list = items.collect { |item|
      item.fetch("summary", "")
    }.uniq
     .join(", ")

    summary_list.present? ? content_tag(:span, "Summary", class: "summary-label badge") + " #{summary_list}" : ""
  end

  def availability_status_display(item)
    content_tag(:span, "", class: item.fetch("icon", "")) + item.fetch("availability", "")
  end

  def non_circulating_display(item)
    content_tag(:p, "", class: "m-2") +
    content_tag(:span, "", data: { toggle: "tooltip", placement: "bottom", container: "body" }, title: "#{t('tooltip.online_only')}", tabindex: "0", class: "information-icon") + "Onsite only"
  end
end
