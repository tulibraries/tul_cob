import { Controller } from "@hotwired/stimulus"
import { whenBlacklightReady } from "../../legacy/blacklight_helpers"

export default class extends Controller {
  connect() {
    this.load()
  }

  load() {
    fetch(this.data.get("url"))
    .then(response => response.text())
    .then(html => {
      this.element.innerHTML = html
      whenBlacklightReady((Blacklight) => {
        if (typeof Blacklight.doBookmarkToggleBehavior === "function") {
          Blacklight.doBookmarkToggleBehavior()
        }
      })
    })
  }
}
