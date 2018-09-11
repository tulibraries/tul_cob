import { Controller } from "stimulus"

  function getMetaValue(name) {
    const element = document.head.querySelector(`meta[name="${name}"]`)
    return element.getAttribute("content")
  }

export default class extends Controller {
  static targets = [ "panel", "spinner", "request" ]

  initialize() {
    this.availability()
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
        $(this.spinnerTarget).remove();
        this.panelTarget.innerHTML = html
        $(this.panelTarget).parent().removeClass("hidden");
        $("#requests-container").removeClass("hidden");
        var mms_id = $("#record-view-iframe").data("availability-id");
        var requests_url = $("#request-url-data-" + mms_id).data("requests-url");
        $("#request-btn-0").attr("href", requests_url);
      })
  }
}
