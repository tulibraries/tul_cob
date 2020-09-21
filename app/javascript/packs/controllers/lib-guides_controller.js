import { Controller } from "stimulus"

function getMetaValue(name) {
  const element = document.head.querySelector(`meta[name="${name}"]`)
  return element.getAttribute("content")
}

export default class extends Controller {
  static targets = [ "card", "flex", "heading", "noresults", "panel" ];

  initialize() {
    fetch(this.data.get("url"), {
      credentials: "same-origin",
      headers: {
        "X-CSRF-Token": getMetaValue("csrf-token")
      },
    })
      .then(response => response.text())
      .then(html => {
        this.cardTarget.innerHTML = html

        if (this.hasNoresultsTarget) {
          this.panelTarget.classList.add("hidden");
        }

        if (this.cardTarget.classList.contains("catalog-guides")) {
          this.flexTargets.forEach((t) => t.classList.add("flex-fill", "p-4", "rounded", "mx-md-3"));
          this.flexTargets.forEach((t) => t.classList.remove("border-top", "border-red", "p-3"));
        }

        if (this.cardTarget.classList.contains("bento-guides")) {
          this.headingTargets.forEach((t) => t.classList.add("lib-guides-recommender-bento-heading"));
        }
    });
  }
}
