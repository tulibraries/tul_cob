# frozen_string_literal: true

module BibItem
  extend ActiveSupport::Concern

  def non_circulating_items(item)
    item.non_circulating? ||
    item.location == "reserve" ||
    item.circulation_policy == "Bound Journal"
  end

  def description(item)
    item["description"] ? "#{item['description']}" : ""
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

  def public_note(item)
    item["description"] ? "; " : ""
    item["public_note"] ? "Note: #{item['public_note']}" : ""
  end

  def location(item)
    item["current_location"] ? item["current_location"] : item["permanent_location"]
  end
end
