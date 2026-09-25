import $ from "jquery"
import "@hotwired/turbo-rails"
import "@selectize/selectize"
import selectizeOptions from "selectize_options"
import "legacy"
import "bootstrap"
import "controllers"
import Blacklight from "blacklight-frontend"
import BlacklightRangeLimit from "blacklight-range-limit"

const initializeSelectize = () => {
  if (typeof $.fn.selectize !== "function") return

  $("select.selectize").each(function initializeSelectizeControl() {
    if (!this.selectize) $(this).selectize(selectizeOptions)
  })
}

const handleSkipLinkClick = (event) => {
  const link = event.target.closest?.("#skip-link a[href^='#']")
  if (!link) return

  const target = document.getElementById(decodeURIComponent(link.hash.slice(1)))
  if (!target) return

  event.preventDefault()
  window.history.pushState({}, "", link.hash)
  if (target.tabIndex < 0 && !target.hasAttribute("tabindex")) {
    target.setAttribute("tabindex", "-1")
  }
  target.focus({ preventScroll: true })
  target.scrollIntoView()
  window.setTimeout(initializeSelectize, 0)
}

document.addEventListener("turbo:load", initializeSelectize)
document.addEventListener("DOMContentLoaded", initializeSelectize, { once: true })
document.addEventListener("click", handleSkipLinkClick, true)

if (document.readyState !== "loading") initializeSelectize()

BlacklightRangeLimit.init({ onLoadHandler: Blacklight.onLoad });
