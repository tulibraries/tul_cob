/**
 * AlmaIntegration is a Javascript class for integration with Alma.
 * AJAX calls are made to endpoints on the Rails server that
 * in turn communicate with Alma.
 */

function AlmaIntegration(options = {}) {
    this.MAX_AJAX_ATTEMPTS = options.maxAjaxAttempts || 3;
    this.BATCH_SIZE = options.batchSize || 10;
}

/**
 * Subclasses should override to customize. To filter out a holding from display,
 * this function can return null.
 * @param holding
 * @returns {string}
 */

const availabilityButton = (id, holding) => {
  const availButton = $("button[data-availability-ids='" + id + "']");
  if (!$(availButton).hasClass("available")) {
    if (holding["availability"] === "available") {
      $(availButton).html("<span class='avail-label available'>Available</span>");
      $(availButton).removeClass("btn-default");
      $(availButton).addClass("collapsed collapse-button available availability-btn");
      $(availButton).show();
    }
    else if (holding["availability"] === "check_holdings") {
      $(availButton).html("<span class='avail-label available'>Available</span>");
      $(availButton).removeClass("btn-default");
      $(availButton).addClass("collapsed collapse-button available availability-btn");
      $(availButton).show();
    }
    else {
      unavailableItems(id);
    }
  }
};

const noHoldingsAvailabilityButton = (id) => {
  unavailableItems(id);
};

const unavailableItems = (id) => {
  const availButton = $("button[data-availability-ids='" + id + "']");

  $(availButton).html("<span class='avail-label not-available'>Not Available</span>");
  $(availButton).removeClass("btn-default");
  $(availButton).addClass("btn-warning collapsed collapse-button availability-btn");
  $(availButton).show();
};

const availabilityInfo = (holding) => {
  let library = holding["library"];
  if (library === "ASRS" || library === "Paley Library") {
    library = "Charles Library";
  }

  const availability = holding["availability"];

  if (library !== "EMPTY") {
    if (availability === "available") {
      return { library, availability };
    }

    if (availability === "check_holdings") {
      return { library, availability };
    }
  }

  return undefined;
};

AlmaIntegration.prototype.formatHolding = function (holding) {
  if (holding["inventory_type"] === "physical") {
    return availabilityInfo(holding);
  }

  return undefined;
};

const sortedLibraries = (holdings) => {
  holdings.sort();
  if (holdings.indexOf("Charles Library") > 0) {
    holdings.splice(holdings.indexOf("Charles Library"), 1);
    holdings.unshift("Charles Library");
  }
};

const availableHoldings = (holdings) => {
  const availHoldings = [];
  holdings.forEach((item) => {
    if (item.availability === "available") {
      availHoldings.push(item.library);
    }
  });

  sortedLibraries(availHoldings);

  const list = availHoldings.filter((x, i, a) => {
    return a.indexOf(x) === i;
  });
  return list.join("<br/>");
};

const checkHoldings = (holdings) => {
  const check = [];
  holdings.forEach((item) => {
    if (item.availability === "check_holdings") {
      check.push(item.library);
    }
  });

  sortedLibraries(check);

  const list = check.filter((x, i, a) => {
    return a.indexOf(x) === i;
  });
  return list.join("<br/>");
};

/**
 * Subclasses should override to customize.
 * @param holding
 * @returns {string}
 */
AlmaIntegration.prototype.formatHoldings = function (holdings) {
  let html = "";
  const available = availableHoldings(holdings);
  const check = checkHoldings(holdings);

  if (available) {
    html = "<dt class='index-label'>Available at: </dt><dd>" + available + "</dd>";
  }

  if (check) {
    html += "<dt class='index-label'>Other Libraries: </dt><dd>" + check + "</dd>";
  }
  return html;
};

/**
 * Populates html document with availability status strings
 * @param data
 */
AlmaIntegration.prototype.populateAvailability = function () {
  const baObj = this;

  const idsLoaded = Object.keys(baObj.availability);

  $(".availability-ajax-load").filter((index, element) => {
    return !$(element).hasClass("availability-ajax-loaded");
  }).each((index, element) => {
    const idString = $(element).data("availabilityIds").toString() || "";
    const ids = idString.split(",").filter((s) => { return s.length > 0; });

    // make sure we have data for ALL the ids (this accounts for bibs w/ multiple holdings
    // across boundwiths), otherwise we're not ready to populate yet.
    if (ids.filter((id) => { return idsLoaded.includes(id); }).length !== ids.length) {
      return;
    }
    // jquery's map auto-flattens and strips out nulls
    const html = $.map(ids, (id) => {

      if (baObj.availability[id]) {
        const holdings = baObj.availability[id]["holdings"] || [];
        if (holdings.length > 0) {
          const formatted = $.map(holdings, (holding) => {
            availabilityButton(id, holding);
            return baObj.formatHolding(holding);
          });
          return baObj.formatHoldings(formatted);
        }
        else {
          noHoldingsAvailabilityButton(id);
        }
      }

      return undefined;
    }).join("<br/>");
    baObj.renderAvailability(element, html);
  });
};

/**
 * Renders the passed-in html on the given element
 * @param element
 * @param html
 */
AlmaIntegration.prototype.renderAvailability = function (element, html) {
  $(element).addClass("availability-ajax-loaded");
  $(element).html(html);
};

/**
 * Subclasses should override to customize.
 */
AlmaIntegration.prototype.errorLoadingAvailability = function (idList) {
  const idListArray = idList.split(",");
  $(".availability-ajax-load").filter((idx, element) => {
    const idsOnElement = $(element).data("availabilityIds").toString().split(",");
    const found = $.grep(idListArray, (id) => {
      return idsOnElement.indexOf(id) !== -1;
    }).length > 0;
    return found;
  }).addClass("availability-ajax-loaded").html(
    "<span class='availability-loading-error'>Error loading status for this item</span>"
  );
};

/**
 * Actually makes the AJAX call for availability
 * @param idList String of comma-sep ids
 * @param attemptCount
 */
AlmaIntegration.prototype.loadAvailabilityAjax = function (idList, attemptCount) {
  const baObj = this;
  if (idList.length > 0) {
    const url = $("#alma_availability_url").data("url") + "?id_list=" + encodeURIComponent(idList);
    return $.ajax(url, {
      success: (data, textStatus, jqXHR) => {
        if (!data.error) {
          baObj.availability = Object.assign(baObj.availability, data["availability"]);
          baObj.populateAvailability();
        }
        else {
          if (attemptCount < baObj.MAX_AJAX_ATTEMPTS) {
            if (data.error !== null && typeof data.error === "object") {
              if (data.error["error"] && data.error["error"]["errorMessage"]) {
                const msg = data.error["error"]["errorMessage"];
                const isSingleId = idList.indexOf(",") === -1;
                // this happens when an MMS ID has been deleted in Alma but Discovery hasn't caught up yet
                if (msg.indexOf("Input parameters") !== -1 && msg.indexOf("is not valid.") !== -1 && !isSingleId) {
                  console.log("Invalid MMS ID error from API, retrying batch as individual requests");
                  idList.split(",").forEach((id) => {
                    baObj.availabilityRequestsFinished[id] = false;
                    baObj.loadAvailabilityAjax(id, baObj.MAX_AJAX_ATTEMPTS);
                  });
                }
                else {
                  baObj.errorLoadingAvailability(idList);
                }
              }
            }
            else {
              baObj.loadAvailabilityAjax(idList, attemptCount + 1);
            }
          }
          else {
            baObj.errorLoadingAvailability(idList);
          }
        }
      },
      error: (jqXHR, textStatus, errorThrown) => {
        if (errorThrown !== "timeout") {
          if (attemptCount < baObj.MAX_AJAX_ATTEMPTS) {
            baObj.loadAvailabilityAjax(idList, attemptCount + 1);
          }
          else {
            baObj.errorLoadingAvailability(idList);
          }
        }
      },
      complete: () => {
        baObj.availabilityRequestsFinished[idList] = true;
      }
    });
  }
  // We want to be able to use this in a promise even in show view.
  return Promise.resolve(null);
};

window.AlmaIntegration = AlmaIntegration;

/**
 * Partitions an array into arrays of specified size
 * @param size
 * @param arr
 * @returns {*}
 */
AlmaIntegration.prototype.partitionArray = function (size, arr) {
  if (arr.length === 0) {
    return [];
  }

  return arr.reduce((acc, value, index) => {
    if (index % size === 0 && index !== 0) {
      acc.push([]);
    }
    acc[acc.length - 1].push(value);
    return acc;
  }, [[]]);
};

/**
 * Looks for elements with class availability-ajax-load,
 * batches up the values in their data-availability-id attribute,
 * makes the AJAX request, and replaces the contents
 * of the element with availability information.
 */
AlmaIntegration.prototype.loadAvailability = function () {
  const baObj = this;
  const availabilityUrl = $("#alma_availability_url").data("url");

  if (!availabilityUrl) {
    return;
  }

  baObj.availability = {};
  baObj.availabilityRequestsFinished = {};

  const allIds = $(".availability-ajax-load").map((index, element) => {
    return $(element).data("availabilityIds");
  }).get();

  if (allIds.length === 0) {
    return;
  }

  const idArrays = this.partitionArray(baObj.BATCH_SIZE, allIds);

  idArrays.forEach((idArray) => {
    const idArrayStr = idArray.join(",");
    baObj.availabilityRequestsFinished[idArrayStr] = false;
    baObj.loadAvailabilityAjax(idArrayStr, 1)
      .then(() => { return clickLocationButton(); })
      .then((id) => {
        if (!id) {
          return null;
        }
        return waitForRequestUrlData(id).then((foundId) => { return clickRequestButton(foundId); });
      });
  });

  baObj.checkAndPopulateMissing();
};

/**
 * Looks for #doc-<doc-id> in the URL tries to click associated availability
 *
 * and returns doc-id or null if none was found.
 */
const clickLocationButton = () => {
  const hash = window.location.hash;

  if (hash && hash.match(/^#doc-([0-9]{18})/)) {
    const matches = hash.match(/^#doc-([0-9]{18})/);
    const id = matches[1];
    const elem = document.getElementById("available_button-" + id);
    if (elem) {
      elem.click();
    }
    return id;
  }

  return null;
};

/**
 * Waits for element with id #request-url-data-<id> to appear.
 *
 * Returns a promise for the id passed in.
 */
const waitForRequestUrlData = (id) => {
  return waitForElementById("request-url-data-" + id)
    .then(() => { return id; });
};

/**
 * Continuously checks if an element exists then resolves.
 */
const waitForElementById = async (id) => {
  while (!document.getElementById(id)) {
    // Hack that is supposedly better than SetTimeout
    // https://stackoverflow.com/a/47776379/256854
    await new Promise((resolve) => requestAnimationFrame(resolve));
  }
};

/**
 * Clicks the request button associated with id.
 *
 * Returns the id passed in.
 */
const clickRequestButton = (id) => {
  const elem = document.getElementById("request-btn-" + id);

  if (elem) {
    elem.click();
  }
  return id;
};

/**
 * Periodically checks for all AJAX availability requests to finish, then displays
 * messages for records that we couldn't load availability info for.
 */
AlmaIntegration.prototype.checkAndPopulateMissing = function () {

  const baObj = this;
  for (const key in baObj.availabilityRequestsFinished) {
    if (!baObj.availabilityRequestsFinished[key]) {
      setTimeout(() => { baObj.checkAndPopulateMissing(); }, 1000);
      return;
    }
  }

  $(".availability-ajax-load").filter((index, element) => {
    return !$(element).hasClass("availability-ajax-loaded");
  }).each((index, element) => {
    noHoldingsAvailabilityButton($(element).data("availabilityIds"));
    $(element).html("<span style='color: #A41E35'>No status available for this item</span>");
  });
};
