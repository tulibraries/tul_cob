import { Controller } from "stimulus"

export default class extends Controller {
  static targets = [ "location" ]

  connect() {
    this.load()
  }

  load() {
    fetch(this.data.get("url"))
      .then(response => response.json())
      .then(function(data) {
        console.log(data.response.document)
        let locations = data.response.document.location_display;
        return locations.map(function(location) {
          console.log(location)
          let td = document.querySelector('td.location')
          td.innerHTML = location
        })
    })
  }

  showLocation(index) {
    this.index = index
    this.locationTargets.forEach((el, i) => {

    })
  }
}
