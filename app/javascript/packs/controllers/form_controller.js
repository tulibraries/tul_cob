import { Controller } from "stimulus"

export default class extends Controller {
  static targets = [ ]

  connect() {
    this.booking_end_date()
  }

  initialize() {
    this.required()
  }

  required() {
    $("form input:radio").change(function() {
      if ($("#partial_or_full_true").is(":checked")) {
        $("#digitization-request-form #comment").attr("required", "required");
      } else {
        $("#digitization-request-form #comment").removeAttr("required");
      }
    });
  }

  booking_end_date() {
    $('#booking_start_date').change(function() {
      let dt = new Date($('#booking_start_date').val());
      dt.setDate(dt.getDate() + 8);
      let end = dt.toISOString().split("T")[0]
      $('#booking_end_date').prop('min', $('#booking_start_date').val());
      $('#booking_end_date').prop('max', end);
    });
  }
}
