import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  advanced(e) {
    const hasSearchTerm = Array.from(this.element.querySelectorAll("input[name^='q_']"))
      .some((input) => input.value.trim() !== "")

    if (hasSearchTerm) return

    e.preventDefault()
    const warning = this.element.querySelector("#stimulus-warning")
    if (!warning) return

    warning.textContent = "Please enter a search term."
    warning.style.display = "block"
  }
}
