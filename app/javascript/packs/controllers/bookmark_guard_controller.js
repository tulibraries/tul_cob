import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    guest: Boolean,
    message: String
  }

  handleBookmarkClick(event) {
    if (!this.guestValue) return
    const label = event.target.closest("label.toggle-bookmark")
    const checkbox = event.target.closest("input.toggle-bookmark")
    if (!label && !checkbox) return
    this.showWarning()
  }

  showWarning() {
    if (!this.messageValue) return
    const flashes = document.getElementById("main-flashes")
    const target = flashes || this.element
    let container = target.querySelector(".flash_messages")
    if (!container) {
      container = document.createElement("div")
      container.className = "flash_messages"
      target.prepend(container)
    }
    const existing = container.querySelector(".guest-bookmark-warning")
    if (existing) existing.remove()
    const alert = document.createElement("div")
    alert.className = "alert alert-dismissible alert-warning guest-bookmark-warning"
    alert.textContent = this.messageValue
    const close = document.createElement("button")
    close.className = "btn-close"
    close.setAttribute("type", "button")
    close.setAttribute("aria-label", "Close")
    close.setAttribute("data-dismiss", "alert")
    close.setAttribute("data-bs-dismiss", "alert")
    alert.appendChild(close)
    container.prepend(alert)
  }
}
