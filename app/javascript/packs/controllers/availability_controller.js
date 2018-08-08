import { Controller } from "stimulus"

  function getMetaValue(name) {
      const element = document.head.querySelector(`meta[name="${name}"]`)
      return element.getAttribute("content")
    }

export default class extends Controller {
  static targets = [ "panel", "button", "spinner", "request", "container" ]

  item() {
    this.buttonTarget.classList.toggle("collapsed");

    if (!this.buttonTarget.classList.contains("clicked")) {
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
          this.buttonTarget.classList.add("clicked")
          $(this.panelTarget).parent().removeClass("hidden");
          var mms_id = $(this.buttonTarget).data("availability-ids");
          var requests_url = $("#request-url-data-" + mms_id).data("requests-url");
          $(this.requestTarget).attr("data-requests-url", requests_url);
          $(this.requestTarget).removeClass("hidden");
          this.requestTarget.classList.add("search-results-request-btn")
      })
    }
  }
}
