import { Controller } from "stimulus"

export default class extends Controller {
  static targets = [ "panel", "button", "spinner" ]

  item() {
    this.buttonTarget.classList.toggle("collapsed");

    if (!this.buttonTarget.classList.contains("clicked")) {
      $(this.spinnerTarget).show();
      fetch(this.data.get("url"))
        .then(response => response.text())
        .then(html => {
          this.spinnerTarget.remove();
          this.panelTarget.innerHTML = html
        this.buttonTarget.classList.add("clicked")
      })
    }
  }
}
