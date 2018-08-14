import { Controller } from "stimulus"

export default class extends Controller {
  static targets = [ ]

  connect() {
    this.booking_end_date()
    this.message()
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

  message() {
    let hold_date_field = document.getElementById('hold_date_field').value;
    let digitization_date_field = document.getElementById('digitization_date_field').value;

    if (hold_date_field != "") {
      hold_date_field.setCustomValidity("Please write date in YYYY-MM-DD format.");
    }
    if (digitization_date_field != "") {
      digitization_date_field.setCustomValidity("Please write date in YYYY-MM-DD format.");
    }
  }
}
