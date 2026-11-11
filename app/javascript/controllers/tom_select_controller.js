import { Controller } from "@hotwired/stimulus"
import TomSelect from "tom-select"
import tomSelectOptions from "tom_select_options"

export default class extends Controller {
  connect() {
    this.handleBeforeCache = this.handleBeforeCache.bind(this)
    document.addEventListener("turbo:before-cache", this.handleBeforeCache)

    if (!this.element.tomselect) new TomSelect(this.element, tomSelectOptions)
  }

  disconnect() {
    document.removeEventListener("turbo:before-cache", this.handleBeforeCache)
    this.destroyTomSelect()
  }

  handleBeforeCache() {
    this.destroyTomSelect()
  }

  destroyTomSelect() {
    const control = this.element.tomselect
    if (!control) return

    const selectedValues = [...control.items]
    const labels = Array.from(control.control_input.labels || [])
      .filter((label) => label.htmlFor === control.control_input.id)
    control.destroy()
    labels.forEach((label) => {
      label.htmlFor = this.element.id
    })
    Array.from(this.element.options).forEach((option) => {
      option.selected = selectedValues.includes(option.value)
    })
  }
}
