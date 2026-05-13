# frozen_string_literal: true

pin "application", preload: true
pin "@hotwired/stimulus", to: "stimulus.min.js", preload: true
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js", preload: true
pin "blacklight", to: "blacklight/blacklight.js"

pin_all_from "app/javascript/controllers", under: "controllers"
pin_all_from "app/javascript/legacy", under: "legacy"

pin_all_from "app/javascript/blacklight_range_limit_vendor/flot", under: "flot"
pin "bootstrap-slider", to: "blacklight_range_limit_vendor/bootstrap-slider.js"
pin "blacklight_range_limit_manifest", to: "blacklight_range_limit_manifest.js"
pin_all_from "app/javascript/local_blacklight_range_limit", under: "local_blacklight_range_limit"
