# frozen_string_literal: true

class RequestConfirmation
  attr_reader :request_id, :sent_from, :pickup_location

  def initialize(response, pickup_location = nil)
    @request_id = response&.request_id
    @sent_from = response&.managed_by_library_code
    @pickup_location = pickup_location
  end

  def message
    [I18n.t("requests.default_success"), delivery_estimate_message, I18n.t("requests.request_status_message")].join("")
  end

  def delivery_estimate_message
    RequestDeliveryEstimate.new(sent_from, pickup_location).message
  end
end
