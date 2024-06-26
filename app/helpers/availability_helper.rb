# frozen_string_literal: true

module AvailabilityHelper
  include Blacklight::CatalogHelperBehavior
  include UsersHelper

  PHYSICAL_TYPE_EXCLUSIONS = /BOOK|ISSUE|SCORE|KIT|MAP|ISSBD|GOVRECORD|OTHER/i

  def availability_status(item)
    # Temporary change for Ambler locations, Main storage location
    unavailable_libraries = []
    unavailable_locations = ["ambler", "amb_media", "storage"]

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
    if key == "SCRC"
      render partial: "scrc_instructions", locals: { key:, document: }
    end
  end

  def description(item)
    item["description"] ? "#{item['description']}" : ""
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

  def missing_or_lost?(item)
    process_type = item.fetch("process_type", "")
    !!process_type.match(/MISSING|LOST_LOAN|LOST_LOAN_AND_PAID/)
  end

  def unwanted_library_locations(item)
    location = item.fetch("current_location", "")
    !!location.match(/techserv|UNASSIGNED|intref/) || library(item) == "EMPTY"
  end

  def library(item)
    item["current_library"] ? item["current_library"] : item["permanent_library"]
  end

  def library_name_from_short_code(library_code)
    if !library_name = Rails.configuration.libraries[library_code]
      Honeybadger.notify("Missing library name configuration for: #{library_code}")
      library_name = library_code
    end

    library_name
  end

  def location(item)
    item["current_location"] ? item["current_location"] : item["permanent_location"]
  end

  def location_name_from_short_codes(location_code, library_code = nil)
    Rails.configuration.locations.dig(library_code, location_code) || location_code
  end

  def call_number(item)
    item["temp_call_number"] ? item["temp_call_number"] : item["call_number"]
  end

  def alternative_call_number(item)
    "#{item["alt_call_number"] ? item["alt_call_number"] : call_number(item)}"
  end

  def document_availability_info(document)
    document_items = document.fetch("items_json_display", [])
    document_items.collect { |item| item }
      .reject(&:blank?)
      .reject { |item| missing_or_lost?(item) }
      .reject { |item| unwanted_library_locations(item) }
      .group_by { |item| library(item) }
      .transform_values { |v| v.group_by { |item| location(item) }.sort.to_h }
  end

  def summary_list(items)
    summary_list = items.collect { |item|
      item.fetch("summary", "")
    }.uniq
     .join(", ")

    summary_list.present? ? content_tag(:span, "Summary", class: "summary-label badge") + " #{summary_list}" : ""
  end

  def sort_order_for_holdings(grouped_items)
    sorted_library_hash = {}
    sorted_library_hash.merge!("MAIN" => grouped_items.delete("MAIN")) if grouped_items.has_key?("MAIN")
    sorted_library_hash.merge!("ASRS" => grouped_items.delete("ASRS")) if grouped_items.has_key?("ASRS")
    items_hash = grouped_items.sort_by { |k, v| library_name_from_short_code(k) }.to_h
    sorted_library_hash = sorted_library_hash.merge!(items_hash)
    sorted_library_hash.each do |library, locations|
      unless locations.empty?
        locations.each do |location, items|
          unless items.empty?
            items.sort_by! { |item| [alternative_call_number(item), description(item)] }
          end
        end
      end
    end
    sorted_library_hash
  end

  def materials_location(material)
    Rails.configuration.locations.dig(material["raw_library"], material["raw_location"])
  end

  def item_level_library_name(location_hash)
    location_hash.transform_values do |v|
      v.reduce({}) { |acc, lib|
        acc.merge!(library_name_from_short_code(lib) => lib)
      }
    end
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
