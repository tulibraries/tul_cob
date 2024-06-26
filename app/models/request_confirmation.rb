# frozen_string_literal: true

class RequestConfirmation
  include AvailabilityHelper

  attr_reader :request_id
  attr_reader :sent_from
  attr_reader :pickup_location

  def initialize(response, pickup_location = nil)
    @request_id = response&.request_id
    @sent_from = response&.managed_by_library_code
    @pickup_location = pickup_location
  end

  def message
    I18n.t("requests.default_success_message") + delivery_estimate_message + I18n.t("requests.request_status_message")
  end

  def delivery_estimate
      if pickup_location == "JAPAN" || pickup_location == "ROME" || pickup_location.blank?
        nil
      elsif pickup_location == "MAIN" && sent_from == "ASRS"
        "1 hour, delivered from the Charles Library BookBot when open"
      elsif pickup_location == sent_from
        "1-2 business days"
      else
        "1-3 business days"
      end
  end

  def delivery_estimate?
    delivery_estimate.present?
  end

  def delivery_estimate_message
    pickup_location_name = library_name_from_short_code(pickup_location)

    if delivery_estimate?
      I18n.t("requests.delivery_estimate_message", pickup: pickup_location_name, estimate: delivery_estimate)
    else
      ""
    end
  end
end
