# frozen_string_literal: true

class RequestConfirmation
  include ActionView::Helpers::TagHelper
  include ActionView::Context # Required for `content_tag` and `tag` to work properly

  attr_reader :request_id, :sent_from, :pickup_location

  def initialize(response, pickup_location = nil)
    @request_id = response&.request_id
    @sent_from = response&.managed_by_library_code
    @pickup_location = pickup_location
  end

  def message
    msg = tag.div class: %(check-mark)
    msg += tag.p class: "request-confirmation mb-0" do
              content_tag(:strong, I18n.t("requests.default_success")) +
              tag.br +
              delivery_estimate_message + " " + I18n.t("requests.request_status_message")
            end
    msg.html_safe
  end

  def delivery_estimate_message
    RequestDeliveryEstimate.new(sent_from, pickup_location).message
  end
end
