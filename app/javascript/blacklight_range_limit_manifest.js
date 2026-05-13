// Master manifest file for engine, so local app can require
// this one file, but get all our files -- and local app
// require does not need to change if we change file list.
//
// Note JQuery is required to be loaded for flot and blacklight_range_limit
// JS to work, expect host app to load it.

window.BlacklightRangeLimit = window.BlacklightRangeLimit || {}

import "flot/jquery.canvaswrapper"
import "flot/jquery.colorhelpers"
import "flot/jquery.flot"
import "flot/jquery.flot.browser"
import "flot/jquery.flot.saturated"
import "flot/jquery.flot.drawSeries"
import "flot/jquery.flot.hover"
import "flot/jquery.flot.uiConstants"
import "flot/jquery.flot.selection"

import "bootstrap-slider"

import "local_blacklight_range_limit/range_limit_shared"
import "local_blacklight_range_limit/range_limit_shared"
import "local_blacklight_range_limit/range_limit_plotting"
import "local_blacklight_range_limit/range_limit_slider"
import "local_blacklight_range_limit/range_limit_distro_facets"
