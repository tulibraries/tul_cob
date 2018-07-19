import { Controller } from "stimulus"

  function getMetaValue(name) {
    const element = document.head.querySelector(`meta[name="${name}"]`)
    return element.getAttribute("content")
  }

export default class extends Controller {
  static targets = [ "panel", "spinner" ]



  initialize() {
      $(this.spinnerTarget).show();
      fetch(this.data.get("url"), {
        credentials: "same-origin",
        headers: {
          "X-CSRF-Token": getMetaValue("csrf-token")
        },
      })
        .then(response => response.text())
        .then(html => {
          this.spinnerTarget.remove();
          this.panelTarget.innerHTML = html
          $(this.panelTarget).parent().removeClass("hidden");
      })
  }
}
