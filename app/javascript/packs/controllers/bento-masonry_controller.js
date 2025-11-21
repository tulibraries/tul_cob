import { Controller } from "@hotwired/stimulus"
import Masonry from "masonry-layout"

export default class extends Controller {
  connect() {
    this.initialize()
  }

  disconnect() {
    this.destroy()
  }

  initialize() {
    if (this.masonry || !this.element) return

    this.masonry = new Masonry(this.element, {
      itemSelector: ".bento_compartment_new",
      percentPosition: true,
      horizontalOrder: true,
      gutter: 24,
    })
  }

  destroy() {
    if (this.masonry) {
      this.masonry.destroy()
      this.masonry = null
    }
  }
}
