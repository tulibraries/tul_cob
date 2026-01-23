/* eslint no-console:0 */
// This file is automatically compiled by Webpack, along with any other files
// present in this directory. You're encouraged to place your actual application logic in
// a relevant structure within app/javascript and only use these pack files to reference
// that code so it'll be compiled.
//
// To reference this file, add <%= javascript_pack_tag 'application' %> to the appropriate
// layout file, like app/views/layouts/application.html.erb
import "@hotwired/turbo-rails"
import "@stimulus/polyfills"
import "whatwg-fetch"
import { Application } from "@hotwired/stimulus"
import { definitionsFromContext } from "stimulus/webpack-helpers"
import BlacklightRangeLimit from "blacklight-range-limit"
import "bootstrap"
import "selectize"

import "../channels"
import "../legacy/jquery"
import "../legacy/polyfills"
import "../legacy/dom_behaviors"
import "../legacy/availability"
import "../legacy/summary_previews"
import "../legacy/blacklight_overrides"
import "../legacy/article_iframe"
import "../legacy/libwizard_tutorial"
import { whenBlacklightReady } from "../legacy/blacklight_helpers"

const application = Application.start()
const context = require.context("./controllers", true, /\.js$/)
application.load(definitionsFromContext(context))

whenBlacklightReady((Blacklight) => {
  if (typeof Blacklight.onLoad === "function") {
    BlacklightRangeLimit.init({ onLoadHandler: Blacklight.onLoad })
  }
})
