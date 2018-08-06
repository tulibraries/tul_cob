import { Controller } from "stimulus"

  function getMetaValue(name) {
    const element = document.head.querySelector(`meta[name="${name}"]`)
    return element.getAttribute("content")
  }

export default class extends Controller {
  static targets = [ "panel", "spinner", "request" ]



  initialize() {
    this.availability()
    this.request()
  }

  availability() {
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
        $("#requests-container").remove();
        $(this.panelTarget).parent().removeClass("hidden");
      })
  }

  request() {
    fetch(this.data.get("url"), {
      credentials: "same-origin",
      headers: {
        "X-CSRF-Token": getMetaValue("csrf-token")
      },
    })
      .then(response => response.text())
      .then(html => {
        this.requestTarget.innerHTML = html
        $("#availability-container").remove();
        $("#error-message").remove();
      })
  }
}
