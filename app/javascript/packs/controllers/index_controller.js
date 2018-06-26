import { Controller } from "stimulus"

export default class extends Controller {
  connect() {
    this.load()
  }

  load() {
    fetch(this.data.get("url"))
    .then(response => response.text())
    .then(html => {
      this.element.innerHTML = html
      Blacklight.do_bookmark_toggle_behavior();
    })
  }
}
