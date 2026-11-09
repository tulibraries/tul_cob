import "jquery"
import "@hotwired/turbo-rails"
import TomSelect from "tom-select"
import tomSelectOptions from "tom_select_options"
import "legacy"
import "bootstrap"
import "controllers"
import Blacklight from "blacklight-frontend"
import BlacklightRangeLimit from "blacklight-range-limit"

const initializeTomSelect = () => {
  document.querySelectorAll("select.tom-select").forEach((element) => {
    if (!element.tomselect) new TomSelect(element, tomSelectOptions)
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
  window.setTimeout(initializeTomSelect, 0)
}

document.addEventListener("turbo:load", initializeTomSelect)
document.addEventListener("DOMContentLoaded", initializeTomSelect, { once: true })
document.addEventListener("click", handleSkipLinkClick, true)

if (document.readyState !== "loading") initializeTomSelect()

BlacklightRangeLimit.init({ onLoadHandler: Blacklight.onLoad });
