import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["content"]

  async copy(event) {
    event.preventDefault()

    const content = this.hasContentTarget ? this.contentTarget : null
    const text = content ? content.innerText.trim() : ""

    if (!text) {
      return
    }

    if (navigator.clipboard?.write && typeof ClipboardItem !== "undefined" && window.isSecureContext) {
      try {
        const html = content.innerHTML
        const clipboardItem = new ClipboardItem({
          "text/html": new Blob([html], { type: "text/html" }),
          "text/plain": new Blob([text], { type: "text/plain" })
        })

        await navigator.clipboard.write([clipboardItem])
        return
      } catch (error) {
        console.warn("Rich-text citation copy failed; falling back to plain text", error)
      }
    }

    if (navigator.clipboard?.writeText && window.isSecureContext) {
      try {
        await navigator.clipboard.writeText(text)
        return
      } catch (error) {
        console.warn("Plain-text citation copy failed; trying legacy fallback", error)
      }
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
