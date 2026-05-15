import { Controller } from "@hotwired/stimulus"
import "jquery"
import "@selectize/selectize"
import selectizeOptions from "selectize_options"

export default class extends Controller {
  connect() {
    this.handleBeforeCache = this.handleBeforeCache.bind(this)
    document.addEventListener("turbo:before-cache", this.handleBeforeCache)

    const $ = window.jQuery
    if (typeof $?.fn?.selectize !== "function" || this.element.selectize) return

    $(this.element).selectize(selectizeOptions)
  }

  disconnect() {
    document.removeEventListener("turbo:before-cache", this.handleBeforeCache)
    this.destroySelectize()
  }

  handleBeforeCache() {
    this.destroySelectize()
  }

  destroySelectize() {
    this.element.selectize?.destroy()
  }
}
