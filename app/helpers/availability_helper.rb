# frozen_string_literal: true

module AvailabilityHelper
  include Blacklight::CatalogHelperBehavior

  PHYSICAL_TYPE_EXCLUSIONS = /BOOK|ISSUE|SCORE|KIT|MAP|ISSBD|GOVRECORD|OTHER/i

  def availability_status(item)
    if item.in_place? && item.item_data["requested"] == false
      if item.non_circulating? || item.location == "reserve" ||
          item.circulation_policy == "Bound Journal" ||
          item.circulation_policy == "Music Restricted"
        content_tag(:span, "", class: "check") + "Library Use Only"
      else
        content_tag(:span, "", class: "check") + "Available"
      end
    else
      unavailable_items(item)
    end
  end

  def unavailable_items(item)
    if item.item_data["requested"] == true
      process_type = "Requested"
      content_tag(:span, "", class: "close-icon") + process_type
    elsif item.has_process_type?
      process_type = Rails.configuration.process_types[item.process_type] || "Checked out or currently unavailable"
      content_tag(:span, "", class: "close-icon") + process_type

    else
      content_tag(:span, "", class: "close-icon") + "Checked out or currently unavailable"
    end
  end

  def document_and_api_merged_results(document, items_list)
    document_items = document.fetch("items_json_display", [])
    alma_item_pids = items_list.collect { |k, v|
          v.map { |item| item["item_data"]["pid"] }
        }.flatten

    alma_item_availability = items_list.collect { |k, v|
      v.collect { |item| availability_status(item) }
    }.flatten

    document_items.collect { |item|
        alma_data_array = alma_item_pids.zip(alma_item_availability)
        alma_data_array.collect { |avail_item|
          if item["item_pid"] == avail_item.first
            item.merge!("availability": avail_item.last)
          end
        }.compact
      }
      .flatten
      .reject(&:blank?)
      .reject { |item| missing_or_lost?(item) }
      .reject { |item| unwanted_locations(item) }
      .group_by { |item| library(item) }
  end


  def description(item)
    item["description"] ? "Description: #{item['description']}" : ""
  end

  def material_type(item)
    return unless item["material_type"].present?

    type = item["material_type"]

    if !type.match(PHYSICAL_TYPE_EXCLUSIONS)
      return item["material_type"]
    end
  end

  def public_note(item)
    item["public_note"] ? "Note: #{item['public_note']}" : ""
  end

  def missing_or_lost?(item)
    process_type = item.fetch("process_type", "")
    !!process_type.match(/MISSING|LOST_LOAN/)
  end

  def unwanted_locations(item)
    location = item.fetch("current_location", "")
    !!location.match(/techserv|UNASSIGNED|intref|asrs/)
  end

  def library(item)
    item["current_library"] ? item["current_library"] : item["permanent_library"]
    end

  def library_name_from_short_code(short_code)
    Rails.configuration.libraries[short_code]
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
    item["alt_call_number"] ? item["alt_call_number"] : call_number(item)
  end

  def document_availability_info(document)
    document_items = document.fetch("items_json_display", [])
    document_items.collect { |item| item }
      .reject(&:blank?)
      .reject { |item| missing_or_lost?(item) }
      .reject { |item| unwanted_locations(item) }
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
