# frozen_string_literal: true

module AlmaDataHelper
  include Blacklight::CatalogHelperBehavior

  def availability_status(item)
    if item["item_data"]["base_status"]["value"] == "1"
      "Available"
    elsif item["item_data"]["base_status"]["value"] == "0"
      "Checked out or currently unavailable"
    end
  end

  def description(item)
    if item["item_data"]["description"].present?
      return "Description: " + item["item_data"]["description"]
    end
  end

  def public_note(item)
    if item["item_data"]["public_note"].present?
      return "Note: " + item["item_data"]["public_note"]
    end
  end

  def location_status(item)
    if item["holding_data"]["in_temp_location"] == true
      if item["holding_data"]["temp_call_number"].empty?
        "#{item["holding_data"]["temp_location"]["desc"]}"
      else
        "#{item["holding_data"]["temp_location"]["desc"]} - #{item["holding_data"]["temp_call_number"]}"
      end
    else
      "#{Rails.configuration.locations[item["item_data"]["library"]["value"]][item["item_data"]["location"]["value"]]} - #{item["holding_data"]["call_number"]}"
    end
  end

  def library_status(item)
    if item["holding_data"]["in_temp_location"] == true

      Rails.configuration.libraries[item["holding_data"]["temp_library"]["value"]]
    else
      Rails.configuration.libraries[item["item_data"]["library"]["value"]]
    end
  end

  def alternative_call_number(item)
    if item["item_data"]["alternative_call_number"].present?
      "(Also found under #{item["item_data"]["alternative_call_number"]})"
    end
  end
end
