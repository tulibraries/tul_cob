# frozen_string_literal: true

module AvailabilityHelper
  include Blacklight::CatalogHelperBehavior
  include UsersHelper

  PHYSICAL_TYPE_EXCLUSIONS = /BOOK|ISSUE|SCORE|KIT|MAP|ISSBD|GOVRECORD|OTHER/i

  def availability_status(item)
    unavailable_libraries = []
    # Temporary change for items that don't currently fit in the ASRS bins
    unavailable_locations = ["storage"]

    if item.location == "reserve" && %w(MAIN AMBLER).include?(item.library)
      return unavailable_items(item)
    end

    if unavailable_libraries.include?(item.library) ||
        unavailable_locations.include?(item.location)

      label = "In temporary storage"

      if !campus_closed?
        library_link = "#{Rails.configuration.library_link}forms/storage-request"
        label += " — #{link_to("Recall item now", library_link)}"
      end

      content_tag(:span, "", class: "close-icon") + raw(label)
    elsif item.item_data["awaiting_reshelving"]
      content_tag(:span, "", class: "close-icon") + "Awaiting Reshelving"
    elsif item.in_place? && item.item_data["requested"] == false
      if item.non_circulating? || item.location == "reserve" ||
          item.circulation_policy == "Bound Journal"
        content_tag(:span, "", class: "check") + "Library Use Only"
      else
        content_tag(:span, "", class: "check") + "Available"
      end
    elsif item.in_place? && item.item_data["requested"] == true
      content_tag(:span, "", class: "check") + "Available (Pending Request)"
    else
      unavailable_items(item)
    end
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

    if item.location == "reserve" && %w(MAIN AMBLER).include?(item.library)
      return content_tag(:span, "", class: "close-icon") + "Not Available"
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

  def main_stacks_message(key, document)
    open_shelf_locations = /hirsch|juvenile|leisure|newbooks|stacks/i
    current_locations = document["items_json_display"]&.collect { |item| open_shelf_locations.match(item["current_location"]) }

    key == "MAIN" && current_locations.any?
  end

  def library_specific_instructions(key, document)
    case key
    when "ASRS"
      # REMOVED WHILE LIBRARIES CLOSED
      #render partial: "asrs_instructions", locals: { key: key }
    when "SCRC"
      render partial: "scrc_instructions", locals: { key: key, document: document }
    when "MAIN"
      # REMOVED WHILE LIBRARIES CLOSED
      # if main_stacks_message(key, document)
      #   render partial: "main_open_shelving_instructions", locals: { key: key, document: document }
      # end
    end
  end

  def description(item)
    item["description"] ? "Description: #{item['description']}" : ""
  end

  def material_type(item)
    return unless item["material_type"].present?

    type = item["material_type"]

    if !type.match(PHYSICAL_TYPE_EXCLUSIONS)
      return Rails.configuration.material_types[type]
    end
  end

  def public_note(item)
    item["public_note"] ? "Note: #{item['public_note']}" : ""
  end

  def missing_or_lost?(item)
    process_type = item.fetch("process_type", "")
    !!process_type.match(/MISSING|LOST_LOAN/)
  end

  def unwanted_library_locations(item)
    location = item.fetch("current_location", "")
    !!location.match(/techserv|UNASSIGNED|intref/) || library(item) == "EMPTY"
  end

  def library(item)
    item["current_library"] ? item["current_library"] : item["permanent_library"]
  end

  def library_name_from_short_code(short_code)
    if !library_name = Rails.configuration.libraries[short_code]
      Honeybadger.notify("Missing library name configuration for: #{short_code}")
      library_name = short_code
    end

    library_name
  end

  def location(item)
    item["current_location"] ? item["current_location"] : item["permanent_location"]
  end

  def location_status(item)
    location_name_from_short_code(item)
  end

  def location_name_from_short_code(item)
    Rails.configuration.locations.dig(library(item), location(item)) || location(item)
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
  end

  def summary_list(items)
    summary_list = items.collect { |item|
      item.fetch("summary", "")
    }.uniq
     .join(", ")

    summary_list.present? ? "Description: #{summary_list}" : ""
  end

  def render_holdings_summary(items)
    items.collect { |item|
      if item["summary"].present?
        "Description: " + item["summary"]
      else
        "We are unable to find availability information for this record. Please contact the library for more information."
      end
    }
  end

  def sort_order_for_holdings(grouped_items)
    sorted_library_hash = {}
    sorted_library_hash.merge!("MAIN" => grouped_items.delete("MAIN")) if grouped_items.has_key?("MAIN")
    sorted_library_hash.merge!("ASRS" => grouped_items.delete("ASRS")) if grouped_items.has_key?("ASRS")
    items_hash = grouped_items.sort_by { |k, v| library_name_from_short_code(k) }.to_h
    sorted_library_hash = sorted_library_hash.merge!(items_hash)
    sorted_library_hash.each do |lib, items|
      unless items.empty?
        items.sort_by! { |item| [location_name_from_short_code(item), alternative_call_number(item), description(item)] }
      end
    end
    sorted_library_hash
  end

  def render_location_selector(document)
    materials = document.materials

    if materials.count > 1
      render template: "almaws/_location_selector", locals: { materials: materials }
    elsif materials.count == 1
      render template: "almaws/_location_field", locals: { material: materials.first }
    end
  end

  def render_non_available_status_only(availability = "Not Available")
    if availability != "Available"
      render template: "almaws/_availability_status", locals: { availability: availability }
    end
  end

  def item_level_library_name(location_hash)
    location_hash.transform_values do |v|
      v.reduce({}) { |acc, lib|
        acc.merge!(library_name_from_short_code(lib) => lib)
      }
    end
  end
end
