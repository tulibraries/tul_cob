import { Controller } from "stimulus"

  function getMetaValue(name) {
      const element = document.head.querySelector(`meta[name="${name}"]`)
      return element.getAttribute("content")
    }

export default class extends Controller {
  static targets = [ "panel", "button", "spinner", "request", "container", "href" ]

  item() {
    this.buttonTarget.classList.toggle("collapsed");

    if (!this.buttonTarget.classList.contains("clicked")) {
      fetch(this.data.get("url"), {
        credentials: "same-origin",
        headers: {
          "X-CSRF-Token": getMetaValue("csrf-token")
        },
      })
        .then(response => response.text())
        .then(html => {
          this.panelTarget.innerHTML = html
          this.buttonTarget.classList.add("clicked")
          $(this.panelTarget).parent().removeClass("hidden");
          $('[data-long-list]').longList();
          // REMOVED WHILE LIBRARIES CLOSED
          //$(this.requestTarget).removeClass("hidden");
          //this.requestTarget.classList.add("search-results-request-btn")
      })
    }
  }

  modal() {
    let mms_id = $(this.buttonTarget).data("availability-ids");
    let requests_url = $("#request-url-data-" + mms_id).data("requests-url");
    $(this.hrefTarget).attr("href", requests_url);
    $(this.hrefTarget).append("<span class='fa fa-spinner ml-1' aria-busy='true' aria-live='polite'></span>")
  }
}
