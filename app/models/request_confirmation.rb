# frozen_string_literal: true

class RequestConfirmation
  attr_reader :request_id, :sent_from, :pickup_location

  def initialize(response, pickup_location = nil)
    @request_id = response&.request_id
    @sent_from = response&.managed_by_library_code
    @pickup_location = pickup_location
  end

  def message
    [I18n.t("requests.default_success_message"), delivery_estimate_message, I18n.t("requests.request_status_message")].join("")
  end

  def delivery_estimate_message
    unless pickup_location.blank? || ["JAPAN", "ROME"].include?(pickup_location)
      RequestDeliveryEstimate.new(sent_from, pickup_location).message
    end
  end
end

class RequestDeliveryEstimate
  include Lookupable

  attr_reader :sent_from, :pickup_location

  def initialize(sent_from = nil, pickup_location = nil)
    @sent_from = sent_from
    @pickup_location = pickup_location
  end

  def duration
    if pickup_location == "MAIN" && sent_from == "ASRS"
      "1 hour"
    elsif pickup_location == "MAIN" && sent_from == "MAIN"
      "1-2 business days"
    elsif pickup_location.present?
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
