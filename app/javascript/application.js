// Entry point for the build script in your package.json
import "@stimulus/polyfills"
import "whatwg-fetch"
import "@hotwired/turbo-rails"
import "./src/jquery"
import * as bootstrap from "bootstrap"
import "./src/application"
import "./src/summary_previews"
import "selectize"
import "./controllers"

import Blacklight from "./blacklight/core"
import "./src/blacklight_overrides"
import "./src/availability"