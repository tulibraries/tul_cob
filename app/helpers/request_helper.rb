# frozen_string_literal: true

module RequestHelper
  include Blacklight::CatalogHelperBehavior

  def request_modal(mms_id, pickup_locations, request_level)
    link_to(t("requests.request_button"), "#", id: "request-btn-#{mms_id}", class: "btn btn-sm btn-primary request-button search-results-request-btn", data: { "blacklight-modal": "trigger", "action": "availability#modal", "target": "availability.href" })
  end
end
