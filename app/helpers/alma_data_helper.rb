# frozen_string_literal: true

module AlmaDataHelper
  include Blacklight::CatalogHelperBehavior

  PHYSICAL_TYPE_EXCLUSIONS = /BOOK|ISSUE|SCORE|KIT|MAP|ISSBD|GOVRECORD|OTHER/i


  def availability_status(item)
    if item.in_place?
      if item.non_circulating?
        content_tag(:span, "", class: "check") + "Library Use Only"
      else
        content_tag(:span, "", class: "check") + "Available"
      end
    else
      unavailable_items(item)
    end
  end

  def unavailable_items(item)
    if item.has_process_type?
      process_type = Rails.configuration.process_types[item.process_type]
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
    type = "#{item&.physical_material_type["value"]}"
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
    Rails.configuration.locations.dig(item.library, item.location)
  end

  def library_name_from_short_code(short_code)
    Rails.configuration.libraries[short_code]
  end

  def location_name_from_short_code(item)
    Rails.configuration.locations.dig(item.library, item.location)
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
end
