import { Controller } from "stimulus"

  function getMetaValue(name) {
    const element = document.head.querySelector(`meta[name="${name}"]`)
    return element.getAttribute("content")
  }

export default class extends Controller {
  static targets = [ "panel", "spinner", "request", "href" ]

  initialize() {
    this.availability()
  }

  availability() {
    fetch(this.data.get("url"), {
      credentials: "same-origin",
      headers: {
        "X-CSRF-Token": getMetaValue("csrf-token")
      },
    })
      .then(response => response.text())
      .then(html => {
        this.panelTarget.innerHTML = html
        // REMOVED WHILE LIBRARIES CLOSED
        //$("#requests-container").removeClass("hidden");
        //$('[data-long-list]').longList();
        //var mms_id = $("#record-view-iframe").data("availability-id");
        //var requests_url = $("#request-url-data-" + mms_id).data("requests-url");
        //$("#request-btn-" + mms_id).attr("href", requests_url);
      })
  }

  loading() {
    $(this.hrefTarget).append("<span class='fa fa-spinner ml-1' aria-busy='true' aria-live='polite'></span>")
  }
}
