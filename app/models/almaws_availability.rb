# frozen_string_literal: true

# This model generates availability information using item data from the Alma API (see alma_rb gem).

class AlmawsAvailability
  # Temporary status changes
  TEMP_LIBRARIES = []
  TEMP_LOCATIONS = []

  def self.new(item)
    if TEMP_LOCATIONS.include?(item.location)
      if item.library.downcase == "main"
        Availability::TemporaryStatus
      else
        Availability::Available
      end
    elsif TEMP_LIBRARIES.include?(item.library)
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
