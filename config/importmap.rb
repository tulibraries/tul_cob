# frozen_string_literal: true

pin "application", preload: true
pin "controllers", to: "controllers/index.js"
pin "tom_select_options", to: "tom_select_options.js"
pin "@hotwired/turbo-rails", to: "turbo.min.js", preload: true
pin "@hotwired/stimulus", to: "stimulus.min.js", preload: true
pin "bootstrap", to: "https://ga.jspm.io/npm:bootstrap@5.3.8/dist/js/bootstrap.esm.js", preload: true

pin_all_from "app/javascript/controllers", under: "controllers"
pin_all_from "app/javascript/legacy", under: "legacy"


pin "jquery", to: "legacy/jquery_setup.js"
pin "jquery-esm", to: "jquery-esm.js"
pin "chart.js", to: "https://ga.jspm.io/npm:chart.js@4.5.1/dist/chart.js", preload: false
pin "@kurkle/color", to: "https://ga.jspm.io/npm:@kurkle/color@0.3.4/dist/color.esm.js", preload: false
pin "@popperjs/core", to: "https://ga.jspm.io/npm:@popperjs/core@2.11.8/lib/index.js"
pin "tom-select", to: "tom-select.js"
pin "masonry-layout", to: "masonry.pkgd.min.js"
