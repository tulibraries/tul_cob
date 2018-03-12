import { Controller } from "stimulus"

export default class extends Controller {
  static targets = [ "location" ]

  connect() {
    this.load()
  }

  load() {
    fetch(this.data.get("url"))
      .then(data => {
        console.log(data);
      })
      //const location = this.locationTarget
      //const newValue = $$c)
      //location.value = newValue
      //return newValue
  }
}
