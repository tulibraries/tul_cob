import "jquery"
import "legacy"
import "@hotwired/turbo-rails"
import { Application } from "@hotwired/stimulus"
import "bootstrap"
import "@selectize/selectize"
import "controllers"
import "channels"
import Blacklight from "blacklight-frontend"
import BlacklightRangeLimit from "blacklight-range-limit"

BlacklightRangeLimit.init({ onLoadHandler: Blacklight.onLoad });

