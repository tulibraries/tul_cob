import { Controller } from "stimulus"

export default class extends Controller {
  static targets = [ "catalog", "primo_central", "bento", "books", "journals" ]

  catalog() {
    this.showOnce("catalog")
  }

  primo_central() {
    this.showOnce("primo_central")
  }

  bento() {
    this.showOnce("bento")
  }

  books() {
    this.showOnce("books")
  }

  journals() {
    this.showOnce("journals")
  }

  showOnce(namespace) {
    let reg = new RegExp("(?:(?:^|.*;\s*)" + namespace + "Once\s*\=\s*([^;]*).*$)|^.*$")
    if (document.cookie.replace(reg, "$1") !== "true") {
        $(this[namespace + "Target"]).remove();
        document.cookie = namespace + "Once=true; expires=Fri, 31 Dec 9999 23:59:59 GMT;";
      }
    }
  }
