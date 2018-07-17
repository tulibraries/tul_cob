import { Controller } from "stimulus"

  function getMetaValue(name) {
    const element = document.head.querySelector(`meta[name="${name}"]`)
    return element.getAttribute("content")
  }

export default class extends Controller {
  static targets = [ "modal", "id", "form" ]

  hold() {
    fetch(this.data.get("url"), {
      credentials: "same-origin",
      headers: {
        "X-CSRF-Token": getMetaValue("csrf-token")
      },
    })
      .then(response => response.text())
      .then(html => {
        this.modalTarget.innerHTML = html
        $(this.idTarget).modal({show: true});
    })
  }

  clear_form() {
    $(this.idTarget).modal({show: false});
    this.formTarget.reset();
  }
}
