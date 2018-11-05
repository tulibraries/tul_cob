import { Controller } from "stimulus"

export default class extends Controller {
  static targets = [ "pickups" ]

  connect() {
    this.booking_end_date()
    this.to_page()
  }

  to_page() {
    $("#to_page").change(function() {
      $("#to_page").prop("min", $("#from_page").val());
    });  }

  booking_end_date() {
    $("#booking_start_date").change(function() {
      let dt = new Date($("#booking_start_date").val());
      dt.setDate(dt.getDate() + 8);
      let end = dt.toISOString().split("T")[0]
      $("#booking_end_date").prop("min", $("#booking_start_date").val());
      $("#booking_end_date").prop("max", end);
    });
  }

  select() {
    // We need this variable to be global so that it doesn't mutate in multiple uses
    if (typeof window.item_level_pickup_locations == "undefined") {
       window.item_level_pickup_locations = $(this.pickupsTarget).html();
    }

    let description = $("#description option:selected").text();
    let date = new Date();
    let emptyOption = $('<option />').attr('value', '');
    let options = $(window.item_level_pickup_locations).filter(`optgroup[label='${description}']`).prepend(emptyOption).html();
    if(options) {
      $(this.pickupsTarget).html(options);
    } else {
      $(this.pickupsTarget).empty();
    }
  }
}
