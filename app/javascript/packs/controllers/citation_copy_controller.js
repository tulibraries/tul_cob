import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["content"]

  copy(event) {
    event.preventDefault()
    const text = this.contentTarget ? this.contentTarget.innerText.trim() : ""
    if (!text) {
      return
    }

    if (navigator.clipboard && window.isSecureContext) {
      navigator.clipboard.writeText(text)
      return
    }

    const textarea = document.createElement("textarea")
    textarea.value = text
    textarea.setAttribute("readonly", "")
    textarea.style.position = "absolute"
    textarea.style.left = "-9999px"
    document.body.appendChild(textarea)
    textarea.select()
    document.execCommand("copy")
    document.body.removeChild(textarea)
  }
}
