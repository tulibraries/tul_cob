# frozen_string_literal: true

module AvailabilityHelper
  include Blacklight::CatalogHelperBehavior
  include UsersHelper

  PHYSICAL_TYPE_EXCLUSIONS = /BOOK|ISSUE|SCORE|KIT|MAP|ISSBD|GOVRECORD|OTHER/i

  def availability_status(item)
    # The arrays below are to add any temporary unavailable statuses to the app (instead of through Alma).
    # Currently there is a temporary change for Main storage location.
    unavailable_libraries = []
    unavailable_locations = ["storage"]

    if unavailable_libraries.include?(item.library) ||
      unavailable_locations.include?(item.location)
      content_tag(:span, "", class: "close-icon") + "Temporarily unavailable"

    elsif item.item_data["awaiting_reshelving"]
      content_tag(:span, "", class: "close-icon") + "Awaiting Reshelving"
    elsif item.in_place? && item.item_data["requested"] == false
      if non_circulating_items(item)
        content_tag(:span, "", class: "check") + "Available" +
        content_tag(:p, "", class: "m-2") +
        content_tag(:span, "", data: { toggle: "tooltip", placement: "bottom", container: "body" }, title: "#{t('tooltip.online_only')}", tabindex: "0", class: "information-icon") + "Onsite only"
      else
        content_tag(:span, "", class: "check") + "Available"
      end
    elsif item.in_place? && item.item_data["requested"] == true
      content_tag(:span, "", class: "check") + "Available (Pending Request)"
    else
      unavailable_items(item)
    end
  end

  def non_circulating_items(item)
    item.non_circulating? ||
    item.location == "reserve" ||
    item.circulation_policy == "Bound Journal"
  end

  def unavailable_items(item)
    if item.has_process_type?
      process_type = Rails.configuration.process_types[item.process_type] || "Checked out or currently unavailable"
      if (item.process_type == "LOAN")
        due_date_time = item["item_data"].fetch("due_date", nil)
        unless (due_date_time.nil?)
          process_type += ", due " + make_date(due_date_time)
        end
      end
      return content_tag(:span, "", class: "close-icon") + process_type
    end

    return content_tag(:span, "", class: "close-icon") + "Checked out or currently unavailable"
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
end
