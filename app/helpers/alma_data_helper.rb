# frozen_string_literal: true

module AlmaDataHelper
  include Blacklight::CatalogHelperBehavior

  PHYSICAL_TYPE_EXCLUSIONS = /BOOK|ISSUE|SCORE|KIT|MAP|ISSBD|GOVRECORD|OTHER/i

  def availability_status(item)
    if item.in_place? && item.item_data["requested"] == false
      if item.non_circulating? || item.location == "reserve"
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

  def description(item)
    if item.description.present?
      return "Description: " + item.description
    end
  end

  def physical_material_type(item)
    return  unless item.physical_material_type.present?

    type = item.physical_material_type["value"].to_s

    if !type.match(PHYSICAL_TYPE_EXCLUSIONS)
      return item.physical_material_type["desc"]
    end
  end

  def public_note(item)
    if item.public_note.present?
      return "Note: " + item.public_note
    end
  end

  def location_status(item)
    location_name_from_short_code(item)
  end

  def location_name_from_short_code(item)
    Rails.configuration.locations.dig(item.library, item.location) || item.location
  end

  def library_name_from_short_code(short_code)
    Rails.configuration.libraries[short_code]
  end

  def alternative_call_number(item)
    if item.has_alt_call_number?
      "(Also found under #{item.alt_call_number})"
    end
  end

  def sort_order_for_holdings(grouped_items)
    sorted_library_hash = {}
    sorted_library_hash.merge!("MAIN" => grouped_items.delete("MAIN")) if grouped_items.has_key?("MAIN")
    items_hash = grouped_items.sort_by { |k, v| library_name_from_short_code(k) }.to_h
    sorted_library_hash = sorted_library_hash.merge!(items_hash)
    sorted_library_hash.each do |lib, items|
      unless items.empty?
        items.sort_by! { |item| [location_name_from_short_code(item), item.call_number, item.description] }
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

  def filter_unwanted_locations(items_list)
    items_list.each_pair { |library, items|
      items_list[library] = items.reject { |item|
        item if item.holding_location.match?(/techserv|UNASSIGNED|intref|asrs/)
      }
    }
  end

  def unsuppressed_holdings(items_list, document)
    solr_holdings = document.fetch("holdings_display", "")

    return if solr_holdings.blank?

    items_list.each_pair { |library, items|
      items_list[library] = items.select { |item|
       solr_holdings.include?(item["holding_data"]["holding_id"])
     }
    }
  end
end
