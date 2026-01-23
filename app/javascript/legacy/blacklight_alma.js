import $ from "./jquery"

const availabilityButton = (id, holding) => {
  if (!$) {
    return
  }

  const availButton = $(`button[data-availability-ids='${id}']`)
  if (availButton.hasClass("available")) {
    return
  }

  if (holding.availability === "available" || holding.availability === "check_holdings") {
    availButton.html("<span class='avail-label available'>Available</span>")
    availButton.removeClass("btn-default")
    availButton.addClass("collapsed collapse-button available availability-btn")
    availButton.show()
  } else {
    unavailableItems(id)
  }
}

const unavailableItems = (id) => {
  if (!$) {
    return
  }
  const availButton = $(`button[data-availability-ids='${id}']`)
  availButton.html("<span class='avail-label not-available'>Not Available</span>")
  availButton.removeClass("btn-default")
  availButton.addClass("btn-warning collapsed collapse-button availability-btn")
  availButton.show()
}

const noHoldingsAvailabilityButton = (id) => {
  unavailableItems(id)
}

const availabilityInfo = (holding) => {
  let library = holding.library
  if (library === "ASRS" || library === "Paley Library") {
    library = "Charles Library"
  }

  if (library === "EMPTY") {
    return null
  }

  if (holding.availability === "available" || holding.availability === "check_holdings") {
    return { library, availability: holding.availability }
  }
  return null
}

const sortedLibraries = (holdings) => {
  holdings.sort()
  const charlesIndex = holdings.indexOf("Charles Library")
  if (charlesIndex > 0) {
    holdings.splice(charlesIndex, 1)
    holdings.unshift("Charles Library")
  }
}

const availableHoldings = (holdings) => {
  const availHoldings = []
  holdings.forEach((item) => {
    if (item.availability === "available") {
      availHoldings.push(item.library)
    }
  })

  sortedLibraries(availHoldings)
  const list = availHoldings.filter((value, index, array) => array.indexOf(value) === index)
  return list.join("<br/>")
}

const checkHoldings = (holdings) => {
  const check = []
  holdings.forEach((item) => {
    if (item.availability === "check_holdings") {
      check.push(item.library)
    }
  })

  sortedLibraries(check)
  const list = check.filter((value, index, array) => array.indexOf(value) === index)
  return list.join("<br/>")
}

const clickLocationButton = () => {
  const { hash } = window.location
  if (hash && hash.match(/^#doc-([0-9]{18})/)) {
    const matches = hash.match(/^#doc-([0-9]{18})/)
    const id = matches[1]
    const button = document.getElementById(`available_button-${id}`)
    button?.click()
    return id
  }
  return null
}

const waitForElementById = async (id) => {
  while (!document.getElementById(id)) {
    // eslint-disable-next-line no-await-in-loop
    await new Promise((resolve) => requestAnimationFrame(resolve))
  }
}

const waitForRequestUrlData = (id) => waitForElementById(`request-url-data-${id}`).then(() => id)

const clickRequestButton = (id) => {
  const element = document.getElementById(`request-btn-${id}`)
  element?.click()
  return id
}

class BlacklightAlma {
  constructor(options = {}) {
    this.MAX_AJAX_ATTEMPTS = options.maxAjaxAttempts || 3
    this.BATCH_SIZE = options.batchSize || 10
    this.availability = {}
    this.availabilityRequestsFinished = {}
  }

  formatHolding(holding) {
    if (holding.inventory_type === "physical") {
      return availabilityInfo(holding)
    }
    return null
  }

  formatHoldings(holdings) {
    let html = ""
    const available = availableHoldings(holdings)
    const check = checkHoldings(holdings)

    if (available) {
      html = `<dt class='index-label'>Available at: </dt><dd>${available}</dd>`
    }

    if (check) {
      html += `<dt class='index-label'>Other Libraries: </dt><dd>${check}</dd>`
    }
    return html
  }

  populateAvailability() {
    if (!$) {
      return
    }

    const idsLoaded = Object.keys(this.availability)

    $(".availability-ajax-load").filter((index, element) => !$(element).hasClass("availability-ajax-loaded"))
      .each((index, element) => {
        const idString = $(element).data("availabilityIds").toString() || ""
        const ids = idString.split(",").filter((s) => s.length > 0)

        if (ids.filter((id) => idsLoaded.includes(id)).length !== ids.length) {
          return
        }

        const html = $.map(ids, (id) => {
          if (this.availability[id]) {
            const holdings = this.availability[id].holdings || []
            if (holdings.length > 0) {
              const formatted = $.map(holdings, (holding) => {
                availabilityButton(id, holding)
                return this.formatHolding(holding)
              })
              return this.formatHoldings(formatted)
            }
            noHoldingsAvailabilityButton(id)
          }
          return null
        }).join("<br/>")
        this.renderAvailability(element, html)
      })
  }

  renderAvailability(element, html) {
    if (!$) {
      return
    }
    $(element).addClass("availability-ajax-loaded")
    $(element).html(html)
  }

  errorLoadingAvailability(idList) {
    if (!$) {
      return
    }

    const idListArray = idList.split(",")
    $(".availability-ajax-load").filter((idx, element) => {
      const idsOnElement = $(element).data("availabilityIds").toString().split(",")
      const found = $.grep(idListArray, (id) => idsOnElement.indexOf(id) !== -1).length > 0
      return found
    }).addClass("availability-ajax-loaded").html(
      "<span class='availability-loading-error'>Error loading status for this item</span>",
    )
  }

  showElementsOnAvailabilityLoad() {
    if (!$) {
      return
    }

    $(".availability-show-on-ajax-load").removeClass("hide").show()
  }

  loadAvailabilityAjax(idList, attemptCount) {
    if (!$ || idList.length === 0) {
      return Promise.resolve(null)
    }

    const url = `${$("#alma_availability_url").data("url")}?id_list=${encodeURIComponent(idList)}`

    return $.ajax(url, {
      success: (data) => {
        if (!data.error) {
          this.availability = Object.assign(this.availability, data.availability)
          this.populateAvailability()
        } else {
          if (attemptCount < this.MAX_AJAX_ATTEMPTS) {
            if (data.error !== null && typeof data.error === "object") {
              if (data.error.error && data.error.error.errorMessage) {
                const msg = data.error.error.errorMessage
                const isSingleId = idList.indexOf(",") === -1
                if (msg.indexOf("Input parameters") !== -1 && msg.indexOf("is not valid.") !== -1 && !isSingleId) {
                  idList.split(",").forEach((id) => {
                    this.availabilityRequestsFinished[id] = false
                    this.loadAvailabilityAjax(id, this.MAX_AJAX_ATTEMPTS)
                  })
                } else {
                  this.errorLoadingAvailability(idList)
                }
              }
            } else {
              this.loadAvailabilityAjax(idList, attemptCount + 1)
            }
          } else {
            this.errorLoadingAvailability(idList)
          }
        }
      },
      error: (_jqXHR, textStatus, errorThrown) => {
        if (errorThrown !== "timeout") {
          if (attemptCount < this.MAX_AJAX_ATTEMPTS) {
            this.loadAvailabilityAjax(idList, attemptCount + 1)
          } else {
            this.errorLoadingAvailability(idList)
          }
        }
      },
      complete: () => {
        this.showElementsOnAvailabilityLoad()
        this.availabilityRequestsFinished[idList] = true
      },
    })
  }

  registerToggleAvailabilityDetails() {
    if (!$) {
      return
    }

    $(".availability-toggle-details").off("click.tulCobAvailability")
    $(".availability-toggle-details").on("click.tulCobAvailability", (event) => {
      const toggleElement = event.currentTarget
      $(toggleElement).closest(".availability-document-container")
        .find(".availability-details-container")
        .each((idx, element) => this.toggleAvailabilityDetailsForRecord(toggleElement, element))
    })
  }

  createIframeElement(url) {
    const iframe = $("<iframe>")
    iframe.attr("class", "availability-details-iframe")
    iframe.attr("title", "Show availability for this record")
    iframe.attr("src", url)
    iframe.attr("style", "width: 100%")
    return iframe
  }

  toggleAvailabilityDetailsForRecord(toggleElement, containerElement) {
    if (!$) {
      return
    }

    if ($(containerElement).find("iframe").length === 0) {
      const url = $(containerElement).data("availabilityIframeUrl")
      const iframe = this.createIframeElement(url)
      $(containerElement).html(iframe)
    } else {
      $(containerElement).find("iframe").remove()
    }
    $(toggleElement).html()
  }

  partitionArray(size, arr) {
    return arr.reduce((acc, value, index) => {
      if (index % size === 0 && index !== 0) {
        acc.push([])
      }
      acc[acc.length - 1].push(value)
      return acc
    }, [[]])
  }

  loadAvailability() {
    if (!$) {
      return
    }

    this.availability = {}
    this.availabilityRequestsFinished = {}

    this.registerToggleAvailabilityDetails()

    const allIds = $(".availability-ajax-load").map((index, element) => $(element).data("availabilityIds")).get()
    const idArrays = this.partitionArray(this.BATCH_SIZE, allIds)

    idArrays.forEach((idArray) => {
      const idArrayStr = idArray.join(",")
      this.availabilityRequestsFinished[idArrayStr] = false
      this.loadAvailabilityAjax(idArrayStr, 1)
        .then(() => clickLocationButton())
        .then((id) => waitForRequestUrlData(id))
        .then((id) => clickRequestButton(id))
    })

    this.checkAndPopulateMissing()
  }

  checkAndPopulateMissing() {
    const unfinished = Object.keys(this.availabilityRequestsFinished)
      .some((key) => !this.availabilityRequestsFinished[key])

    if (unfinished) {
      setTimeout(() => this.checkAndPopulateMissing(), 1000)
      return
    }

    if (!$) {
      return
    }

    $(".availability-ajax-load").filter((index, element) => !$(element).hasClass("availability-ajax-loaded"))
      .each((index, element) => {
        noHoldingsAvailabilityButton($(element).data("availabilityIds"))
        $(element).html("<span style='color: #A41E35'>No status available for this item</span>")
      })
  }
}

export default BlacklightAlma
