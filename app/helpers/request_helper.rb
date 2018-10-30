# frozen_string_literal: true

module RequestHelper
  include Blacklight::CatalogHelperBehavior

  def request_modal(mms_id, document_counter, pickup_locations, request_level)
    link_to("Request", "#", id: "request-btn-#{document_counter}", class: "btn btn-primary request-button search-results-request-btn", data: { "ajax-modal": "trigger", "action": "availability#modal", "target": "availability.href" })
  end
end
