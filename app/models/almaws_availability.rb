# frozen_string_literal: true

# This model generates availability information using item data from the Alma API (see alma_rb gem).

class AlmawsAvailability
  # Temporary change for Ambler locations, Main storage location
  TEMP_LIBRARIES = []
  TEMP_LOCATIONS = ["ambler", "amb_media", "storage"]

  def self.new(item)
    if TEMP_LOCATIONS.include?(item.location) || TEMP_LIBRARIES.include?(item.library)
      Availability::TemporaryStatus
    elsif item.item_data["awaiting_reshelving"]
      Availability::AwaitingReshelving
    elsif item.in_place?
      Availability::Available
    elsif item.has_process_type?
      Availability::Unavailable
    else
      Availability::Base
    end.new(item)
  end
end
