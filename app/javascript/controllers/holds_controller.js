import { Controller } from "@hotwired/stimulus"

  function getMetaValue(name) {
    const element = document.head.querySelector(`meta[name="${name}"]`)
    return element.getAttribute("content")
  }

export default class extends Controller {
  static targets = [ "table", "spinner"]


  connect() {
    this.abortController = new AbortController()
    if (!this.loaded) this.get_holds()
  }

  disconnect() {
    this.abortController.abort()
  }

  get_holds() {
    fetch(this.data.get("url"), {
      credentials: "same-origin",
      headers: {
        "X-CSRF-Token": getMetaValue("csrf-token")
      },
      signal: this.abortController.signal,
    })
      .then(response => response.text())
      .then(html => {
        $(this.spinnerTarget).remove();
        this.tableTarget.innerHTML = html
        this.loaded = true
      })
      .catch(error => {
        if (error.name !== "AbortError") throw error
      })
  }
}
