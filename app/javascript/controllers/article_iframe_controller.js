import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = [ "button" ]

  readAttributes(event) {
    const target = event.target.parentElement;
    const iframeUrl = target.getAttribute("data-iframe-url");
    const id = target.getAttribute("doc-id");
    const iframeDiv = document.getElementById(id);

    if (iframeUrl) {
      if (iframeDiv.getAttribute("processed") == undefined) {
        iframeDiv.setAttribute("processed", true);
        $("<iframe>", {
          src: iframeUrl,
          "class": "bl_alma_iframe",
          id: 'iframe-' + id,
        }).appendTo(iframeDiv);
      }
    } else {
      console.error(`No iFrame src url found for ${id}`);
    }
  }
}