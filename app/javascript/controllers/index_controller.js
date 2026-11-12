import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.abortController = new AbortController()
    this.load()
  }

  disconnect() {
    this.abortController.abort()
  }

  load() {
    fetch(this.data.get("url"), { signal: this.abortController.signal })
    .then(response => response.text())
    .then(html => {
      this.element.innerHTML = html
      Blacklight.doBookmarkToggleBehavior();
    })
    .catch(error => {
      if (error.name !== "AbortError") throw error
    })
  }
}
