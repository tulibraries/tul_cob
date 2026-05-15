import $ from "jquery"
import "@hotwired/turbo-rails"
import "@selectize/selectize"
import selectizeOptions from "selectize_options"
import "legacy"
import "bootstrap"
import "controllers"
import "channels"
import Blacklight from "blacklight-frontend"
import BlacklightRangeLimit from "blacklight-range-limit"

const initializeSelectize = () => {
  if (typeof $.fn.selectize !== "function") return

  $("select.selectize").each(function initializeSelectizeControl() {
    if (!this.selectize) $(this).selectize(selectizeOptions)
  })
}

document.addEventListener("turbo:load", initializeSelectize)
document.addEventListener("DOMContentLoaded", initializeSelectize, { once: true })

if (document.readyState !== "loading") initializeSelectize()

BlacklightRangeLimit.init({ onLoadHandler: Blacklight.onLoad });
