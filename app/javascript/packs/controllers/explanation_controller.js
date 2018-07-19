import { Controller } from "stimulus"

export default class extends Controller {
  static targets = [ "text" ]

  hide() {
    this.textTarget.remove();
  }
}
