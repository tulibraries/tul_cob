import { Controller } from "@hotwired/stimulus"

  function getMetaValue(name) {
    const element = document.head.querySelector(`meta[name="${name}"]`)
    return element.getAttribute("content")
  }

  export default class extends Controller {
    static targets = [  "results" ]

    connect() {
      this.abortController = new AbortController()
      if (!this.loaded) this.load()
    }

    disconnect() {
      this.abortController.abort()
    }

    load() {
      fetch(this.data.get("url"), {
        credentials: "same-origin",
        headers: { "X-CSRF-Token": getMetaValue("csrf-token") },
        signal: this.abortController.signal,
      })
      .then(response => response.text())
      .then(html => {
        this.resultsTarget.innerHTML = html
        $("#related-items-link").removeClass("hidden");
        $("#related-items-link a").click(function (e) {
           e.preventDefault();
           document.querySelector(this.getAttribute("href")).scrollIntoView({
             behavior: "smooth"
           });
         });
        $(".query-heading").removeClass("hidden");
        $(".query-feedback").removeClass("hidden");
        this.loaded = true
      })
      .catch(error => {
        if (error.name !== "AbortError") throw error
      })
  }
}
