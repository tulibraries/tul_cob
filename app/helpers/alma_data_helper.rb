# frozen_string_literal: true

module AlmaDataHelper
  include Blacklight::CatalogHelperBehavior

  def library_name_in_table(document)
    document_show_fields(document).each do |field_name, field|
      if field_name == "library_facet"
        "library_facet"
      end
    end
  end

  def availability_status(item)
    if item["item_data"]["base_status"]["value"] == "1"
      "Available"
    elsif item["item_data"]["base_status"]["value"]  == "0"
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
    if item["holding_data"]["temp_location"]["value"] == true
      item["holding_data"]["in_temp_location"] + " - " + item["holding_data"]["temp_call_number"]
    else
      item["item_data"]["location"]["value"] + " - " + item["holding_data"]["call_number"]
    end
  end

  def library_status(item)
    if item["holding_data"]["temp_library"]["value"] == true
      item["holding_data"]["temp_library"]["value"]
    else
      Rails.configuration.locations[item["item_data"]["library"]["value"]]
    end
  end

end
