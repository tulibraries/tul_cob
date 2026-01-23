import $ from "./jquery"
import { onTurboLoad, onWindowLoad } from "./events"

const SMALL_BREAKPOINT = 768

const moveNavTools = () => {
  if (!$) {
    return
  }

  const navTools = $("#nav-tools")
  const facetIcon = $("#facet-filter-icon")
  const facetPanel = $("#facet-panel-collapse")
  const limitSearchHeading = $(".limit-search-heading")

  if ($(window).width() < SMALL_BREAKPOINT) {
    navTools.insertAfter("#document")
    facetIcon.removeClass("hidden")
    facetPanel.removeClass("show")
    limitSearchHeading.removeClass("d-none")
  } else {
    navTools.insertAfter("#page-links")
    facetIcon.addClass("hidden")
    $("#facet-availability_facet-header").removeClass("collapsed")
  }
}

const registerResizeHandler = () => {
  if (!$) {
    return
  }

  let previousWidth = $(window).width()

  $(window).on("resize.tulCobNav", () => {
    const currentWidth = $(window).width()
    if (currentWidth === previousWidth) {
      return
    }
    previousWidth = currentWidth

    if (currentWidth < SMALL_BREAKPOINT) {
      $("#nav-tools").insertAfter("#document")
      $("#facet-filter-icon").removeClass("hidden")
      $("#facet-panel-collapse").removeClass("show")
      $(".limit-search-heading").addClass("d-none")
    } else {
      $("#nav-tools").insertAfter("#page-links")
      $("#facet-filter-icon").addClass("hidden")
      $("#facet-panel-collapse").addClass("show")
      $(".limit-search-heading").removeClass("d-none")
    }
  })
}

const initTooltips = () => {
  if (!$) {
    return
  }

  $("body").tooltip({ selector: "[data-bs-toggle=\"tooltip\"]" })
}

const normalizeSecondaryDl = () => {
  if (!$) {
    return
  }

  $(".secondary-dl").children("dt").removeClass("col-sm-3 col-md-3").addClass("col-sm-2 col-md-2")
  $(".secondary-dl").children("dd").addClass("ps-md-3")
}

const hideDecorativeImages = () => {
  if (!$) {
    return
  }

  $(".decorative").each(function updateAlt() {
    $(this).attr("alt", "")
  })
}

const registerSelectize = () => {
  if (!$) {
    return
  }

  $(window).trigger("load.bs.select.data-api")
  if (typeof $(".selectize").selectize === "function") {
    $(".selectize").selectize()
  }
}

const registerHierarchyHover = () => {
  if (!$) {
    return
  }

  $(".search-subject").hover(
    function handleEnter() { $(this).prevAll().addClass("field-hierarchy") },
    function handleLeave() { $(this).prevAll().removeClass("field-hierarchy") },
  )
}

const initPageTweaks = () => {
  if (!$) {
    return
  }

  $(() => { $('[data-bs-toggle="tooltip"]').tooltip() })

  if ($(".noresults").length >= 1) {
    $("#sortAndPerPage").remove()
    $("#documents").css("border", "none")
  }

  if ($("div.navbar-form").length === 0) {
    $("#search-navbar").css("padding-left", "15%")
  }

  $(".modal").on("show.bs.modal", () => {
    $(".request-btn").find("span").remove()
  })

  $("#facet-filter-icon").on("click", function toggleFacetIcon() {
    $(this).find("span#facet-icons").toggleClass("open-facet-icon").toggleClass("remove-facet-icon")
  })

  $(".header-links").on("click", function activateHeaderLink() {
    $(this).siblings().removeClass("active")
    $(this).addClass("active")
  })
}

const exposeMenuToggle = () => {
  if (typeof window === "undefined") {
    return
  }

  window.toggle = (target) => {
    if (target === "secondary") {
      document.getElementById("sub-toggler-icon")?.classList.toggle("change")
    } else if (target === "search") {
      document.getElementById("search-toggler-icon")?.classList.toggle("change")
    } else {
      document.getElementById("main-toggler-icon")?.classList.toggle("change")
    }
  }
}

const fixChromeScroll = () => {
  if (typeof window === "undefined") {
    return
  }

  if (!window.location.hash) {
    window.scrollTo(0, 0)
  }
}

const triggerRangeLimitHack = () => {
  if (!$) {
    return
  }
  $("#facet-pub_date_sort").trigger("shown.bs.collapse")
}

onTurboLoad(() => {
  moveNavTools()
  initTooltips()
  normalizeSecondaryDl()
  hideDecorativeImages()
  registerSelectize()
  registerHierarchyHover()
  initPageTweaks()
})

onWindowLoad(() => {
  fixChromeScroll()
  triggerRangeLimitHack()
})

registerResizeHandler()
exposeMenuToggle()

export {
  moveNavTools,
  initTooltips,
  registerResizeHandler,
}
