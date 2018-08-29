import { Controller } from "stimulus"

export default class extends Controller {
  static targets = [ ]

  connect() {
    this.booking_end_date()
    this.to_page()
  }

  to_page() {
    $('#to_page').change(function() {
      $('#to_page').prop('min', $('#from_page').val());
    });  }

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
