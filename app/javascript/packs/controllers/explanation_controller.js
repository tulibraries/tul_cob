import { Controller } from "stimulus"

export default class extends Controller {
  static targets = [ "catalog", "article", "bento" ]

  catalog() {
    this.catalogOnce()
  }

  article() {
    this.articleOnce()
  }

  bento() {
    this.bentoOnce()
  }

  catalogOnce() {
    if (document.cookie.replace(/(?:(?:^|.*;\s*)catalogOnce\s*\=\s*([^;]*).*$)|^.*$/, "$1") !== "true") {
      this.catalogTarget.remove();
      document.cookie = "catalogOnce=true; expires=Fri, 31 Dec 9999 23:59:59 GMT;";
    }
  }

  articleOnce() {
    if (document.cookie.replace(/(?:(?:^|.*;\s*)articleOnce\s*\=\s*([^;]*).*$)|^.*$/, "$1") !== "true") {
      this.articleTarget.remove();
      document.cookie = "articleOnce=true; expires=Fri, 31 Dec 9999 23:59:59 GMT;";
    }
  }

  bentoOnce() {
    if (document.cookie.replace(/(?:(?:^|.*;\s*)bentoOnce\s*\=\s*([^;]*).*$)|^.*$/, "$1") !== "true") {
      this.bentoTarget.remove();
      document.cookie = "bentoOnce=true; expires=Fri, 31 Dec 9999 23:59:59 GMT;";
    }
  }
}
