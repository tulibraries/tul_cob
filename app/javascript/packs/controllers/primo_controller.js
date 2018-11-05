import { Controller } from "stimulus"

export default class extends Controller {
  static targets = [ "q1", "q2", "q3" ]

  advanced(e) {
    if ((this.q1Target.value == "") && (this.q2Target.value == "") && (this.q3Target.value == "")) {
      e.preventDefault();
      $("#stimulus-warning").show();
      $("#stimulus-warning").html("Please enter a search term.");
    }
  }
}
