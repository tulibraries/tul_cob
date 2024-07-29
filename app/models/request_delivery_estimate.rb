# frozen_string_literal: true

class RequestDeliveryEstimate
  include Lookupable

  attr_reader :sent_from, :pickup_location

  def initialize(sent_from = nil, pickup_location = nil)
    @sent_from = sent_from
    @pickup_location = pickup_location
  end

  def duration
    if pickup_location.blank? || ["JAPAN", "ROME"].include?(pickup_location)
      nil
    elsif pickup_location == "MAIN" && sent_from == "ASRS"
      "1 hour"
    elsif pickup_location == "MAIN" && sent_from == "MAIN"
      "1-2 business days"
    else
      "1-3 business days"
    end
  end

  def message
    return nil if duration.nil?
    pickup_location_name = library_name_from_short_code(pickup_location)

    if duration.include?("hour")
      I18n.t("requests.estimate_hours", pickup: pickup_location_name, duration:)
    else
      I18n.t("requests.estimate_days", pickup: pickup_location_name, duration:)
    end
  end
end
