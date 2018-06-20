import { Controller } from "stimulus"

export default class extends Controller {
  static targets = [ "panel", "spinner" ]



  initialize() {
      $(this.spinnerTarget).show();
      fetch(this.data.get("url"))
        .then(response => response.text())
        .then(html => {
          this.spinnerTarget.remove();
          this.panelTarget.innerHTML = html
          $(this.panelTarget).parent().removeClass("hidden");
      })
  }
}
