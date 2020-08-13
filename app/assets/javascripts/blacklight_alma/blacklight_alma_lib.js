/**
 * BlacklightAlma is a Javascript class for integration with Alma.
 * AJAX calls are made to endpoints on the Rails server that
 * in turn communicate with Alma.
 */

var BlacklightAlma = function (options) {
    options = options || {};
    this.MAX_AJAX_ATTEMPTS = options.maxAjaxAttempts || 3;
    this.BATCH_SIZE = options.batchSize || 10;
};

/**
 * Subclasses should override to customize. To filter out a holding from display,
 * this function can return null.
 * @param holding
 * @returns {string}
 */


 availabilityButton = function(id, holding) {
   var availButton = $("button[data-availability-ids='" + id + "']");
   if (!$(availButton).hasClass("btn-success")) {
     if (holding['location_code'] == 'reserve' && (holding['library_code'] == 'AMBLER' || holding['library_code'] == 'MAIN')) {
       unavailableItems(id);
     }
     else if(holding['availability'] == 'available') {
       $(availButton).html("<span class='avail-label available'>Available</span>");
       $(availButton).removeClass("btn-default");
       $(availButton).addClass("btn-success collapsed collapse-button available availability-btn");
       $(availButton).show();
     }
     else if(holding['availability'] == 'check_holdings') {
       $(availButton).html("<span class='avail-label available'>Available</span>");
       $(availButton).removeClass("btn-default");
       $(availButton).addClass("btn-success collapsed collapse-button available availability-btn");
       $(availButton).show();
     }
     else {
       unavailableItems(id);
     }
   }
 }

 noHoldingsAvailabilityButton = function(id) {
   unavailableItems(id);
  }

  unavailableItems = function(id) {
    var availButton = $("button[data-availability-ids='" + id + "']");

    $(availButton).html("<span class='avail-label not-available'>Not Available</span>");
    $(availButton).removeClass("btn-default");
    $(availButton).addClass("btn-warning collapsed collapse-button availability-btn");
    $(availButton).show();
  }

 availabilityInfo = function (holding) {
   var library = holding['library'];
   if (library == 'ASRS' || library == 'Paley Library') {
     library = "Charles Library";
   }

   var availability = holding['availability'];

   if (library != "EMPTY") {
     if (availability == "available")  {
       availItem = {};
       Object.assign(availItem, {library, availability})
       return availItem;
     }

     if (availability == "check_holdings") {
       checkItem = {};
       Object.assign(checkItem, {library, availability})
       return checkItem;
     }
   }
 }

 BlacklightAlma.prototype.formatHolding = function (holding) {
   if(holding['inventory_type'] == 'physical') {
     return availabilityInfo(holding);
   }
 };

 sortedLibraries = function (holdings) {
   holdings.sort();
   if (holdings.indexOf('Charles Library') > 0) {
       holdings.splice(holdings.indexOf('Charles Library'), 1);
       holdings.unshift('Charles Library');
   }
 }

 availableHoldings = function (holdings) {
   availHoldings = [];
   holdings.forEach(function(item) {
     if (item.availability == "available") {
       availHoldings.push(item.library);
     }
   });

   sortedLibraries(availHoldings);

   var list = availHoldings.filter(function (x, i, a) {
     return a.indexOf(x) == i;
   });
   return list.join("<br/>");
 }

 checkHoldings = function (holdings) {
   check = [];
   holdings.forEach(function(item) {
     if (item.availability == "check_holdings") {
       check.push(item.library);
     }
   });

   sortedLibraries(check);

   var list = check.filter(function (x, i, a) {
     return a.indexOf(x) == i;
   });
   return list.join("<br/>");
 }

 /**
  * Subclasses should override to customize.
  * @param holding
  * @returns {string}
  */
 BlacklightAlma.prototype.formatHoldings = function (holdings) {
   html = ""
   available = availableHoldings(holdings);
   check = checkHoldings(holdings);

   if (available) {
     html = "<dt class='index-label col-md-3' >Available at: </dt><dd class='col-md-5 col-lg-7'>" + available + "</dd>";
   }

   if (check) {
   html += "<dt class='index-label col-md-3' >Other Libraries: </dt><dd class='col-md-5 col-lg-7'>" + check + "</dd>";
   }
   return html;
 };

 /**
  * Populates html document with availability status strings
  * @param data
  */
 BlacklightAlma.prototype.populateAvailability = function () {
     var baObj = this;

     var idsLoaded = Object.keys(baObj.availability);

     $(".availability-ajax-load").filter(function(index, element) {
         return ! $(element).hasClass("availability-ajax-loaded");
     }).each(function (index, element) {
         var idString = $(element).data("availabilityIds").toString() || "";
         var ids = idString.split(",").filter(function(s) { return s.length > 0; });

         // make sure we have data for ALL the ids (this accounts for bibs w/ multiple holdings
         // across boundwiths), otherwise we're not ready to populate yet.
         if(ids.filter(function(id) { return idsLoaded.includes(id); }).length != ids.length) {
             return;
         }
         // jquery's map auto-flattens and strips out nulls
         var html = $.map(ids, function(id) {

             if (baObj.availability[id]) {
                 var holdings = baObj.availability[id]['holdings'] || [];
                 if (holdings.length > 0) {
                     var formatted = $.map(holdings, function(holding) {
                       availabilityButton(id, holding);
                       return baObj.formatHolding(holding);
                     });
                     return baObj.formatHoldings(formatted);
                 } else {
                   noHoldingsAvailabilityButton(id);
                 }
             }
         }).join("<br/>");
         baObj.renderAvailability(element, html);
     });
 };

 /**
  * Renders the passed-in html on the given element
  * @param element
  * @param html
  */
 BlacklightAlma.prototype.renderAvailability = function(element, html) {
     $(element).addClass("availability-ajax-loaded");
     $(element).html(html);
 };

 /**
  * Subclasses should override to customize.
  */
 BlacklightAlma.prototype.errorLoadingAvailability = function (idList) {
     var idListArray = idList.split(",");
     $(".availability-ajax-load").filter(function(idx, element) {
         var ids_on_element = $(element).data("availabilityIds").toString().split(",");
         var found = $.grep(idListArray, function(id) {
             return ids_on_element.indexOf(id) != -1;
         }).length > 0;
         return found;
     }).addClass("availability-ajax-loaded").html(
         "<span class='availability-loading-error'>Error loading status for this item</span>");
 };

 /**
  * Shows elements with class indicating that they should be shown
  * after availability is loaded on the page.
  */
 BlacklightAlma.prototype.showElementsOnAvailabilityLoad = function () {
     $(".availability-show-on-ajax-load").removeClass("hide").show();
 };

 /**
  * Actually makes the AJAX call for availability
  * @param idList String of comma-sep ids
  * @param attemptCount
  */
 BlacklightAlma.prototype.loadAvailabilityAjax = function (idList, attemptCount) {
     var baObj = this;
     if(idList.length > 0) {
         var url = $('#alma_availability_url').data('url') + "?id_list=" + encodeURIComponent(idList);
         console.log(url);
         return $.ajax(url, {
             success: function(data, textStatus, jqXHR) {
                 if(!data.error) {
                     console.log(data);
                     baObj.availability = Object.assign(baObj.availability, data['availability']);
                     baObj.populateAvailability();
                 } else {
                     console.log("Attempt #" + attemptCount + " error loading availability for " + idList);
                     console.log(data.error);

                     if(attemptCount < baObj.MAX_AJAX_ATTEMPTS) {

                         if(data.error !== null && typeof data.error === 'object') {
                             if(data.error['error'] && data.error['error']['errorMessage']) {
                                 var msg = data.error['error']['errorMessage'];
                                 var isSingleId = idList.indexOf(",") === -1;
                                 // this happens when an MMS ID has been deleted in Alma but Discovery hasn't caught up yet
                                 if(msg.indexOf("Input parameters") !== -1 && msg.indexOf("is not valid.") !== -1 && !isSingleId) {
                                     console.log("Invalid MMS ID error from API, retrying batch as individual requests");
                                     idList.split(",").forEach(function(id) {
                                         baObj.availabilityRequestsFinished[id] = false;
                                         baObj.loadAvailabilityAjax(id, baObj.MAX_AJAX_ATTEMPTS);
                                     });
                                 } else {
                                     baObj.errorLoadingAvailability(idList);
                                 }
                             }
                         } else {
                             baObj.loadAvailabilityAjax(idList, attemptCount + 1);
                         }

                     } else {
                         baObj.errorLoadingAvailability(idList);
                     }
                 }
             },
             error: function(jqXHR, textStatus, errorThrown) {
                 console.log("Attempt #" + attemptCount + " error loading availability: " + textStatus + ", " + errorThrown);
                 if(errorThrown !== 'timeout') {
                     if(attemptCount < baObj.MAX_AJAX_ATTEMPTS) {
                         baObj.loadAvailabilityAjax(idList, attemptCount + 1);
                     } else {
                         baObj.errorLoadingAvailability(idList);
                     }
                 }
             },
             complete: function() {
                 baObj.showElementsOnAvailabilityLoad();

                 baObj.availabilityRequestsFinished[idList] = true;
             }
         });
     }
     // We want to be able to use this in a promise even in show view.
     return Promise.resolve(null)
 };

 /**
  * Adds click listeners to elements that should toggle the availability details
  * (iframe) for the associated document (determined by shared parent class).
  * This is used for search results page.
  */
 BlacklightAlma.prototype.registerToggleAvailabilityDetails = function() {
     var baObj = this;

     $(".availability-toggle-details").click(function (event) {
         var toggleElement = event.currentTarget;

         $(event.currentTarget).closest(".availability-document-container").find(".availability-details-container").each(function(idx, element) {
             baObj.toggleAvailabilityDetailsForRecord(toggleElement, element);
         });
     });
 };


 BlacklightAlma.prototype.createIframeElement = function(url) {
     var iframe = $("<iframe>");
     iframe.attr("class", "availability-details-iframe");
     iframe.attr("title", "Show availability for this record");
     iframe.attr("src", url);
     iframe.attr("style", "width: 100%");
     return iframe;
 };

 /**
  * Toggles an individual record's availability details (shown in an iframe)
  */
 BlacklightAlma.prototype.toggleAvailabilityDetailsForRecord = function(toggleElement, containerElement) {
     var baObj = this;
     //var newTextForToggle;
     if ($(containerElement).find("iframe").length == 0) {
         var url = $(containerElement).data("availabilityIframeUrl");
         var iframe = baObj.createIframeElement(url);
         $(containerElement).html(iframe);
         //newTextForToggle = $(toggleElement).data("hideText");
     } else {
         $(containerElement).find("iframe").remove();
         //newTextForToggle = $(toggleElement).data("showText");
     }
     $(toggleElement).html();
 };

 /**
  * Partitions an array into arrays of specified size
  * @param size
  * @param arr
  * @returns {*}
  */
 BlacklightAlma.prototype.partitionArray = function(size, arr) {
     return arr.reduce(function(acc, a, b) {
         if(b % size == 0  && b !== 0) {
             acc.push([]);
         }
         acc[acc.length - 1].push(a);
         return acc;
     }, [[]]);
 };

 /**
  * Looks for elements with class availability-ajax-load,
  * batches up the values in their data-availability-id attribute,
  * makes the AJAX request, and replaces the contents
  * of the element with availability information.
  */
 BlacklightAlma.prototype.loadAvailability = function() {
     var baObj = this;

     baObj.availability = {};
     baObj.availabilityRequestsFinished = {};

     this.registerToggleAvailabilityDetails();

     var allIds = $(".availability-ajax-load").map(function (index, element) {
         return $(element).data("availabilityIds");
     }).get();

     var idArrays = this.partitionArray(baObj.BATCH_SIZE, allIds);

     idArrays.forEach(function(idArray) {
         var idArrayStr = idArray.join(",");
         baObj.availabilityRequestsFinished[idArrayStr] = false;
         baObj.loadAvailabilityAjax(idArrayStr, 1)
         .then(_ => { return clickLocationButton() })
         .then(id =>{ waitForRequestUrlData(id)
         .then(id => { clickRequestButton(id) })})
     });

     baObj.checkAndPopulateMissing();
 };

   /**
    * Looks for #doc-<doc-id> in the URL tries to click associated availability
    *
    * and returns doc-id or null if none was found.
    */
   function  clickLocationButton() {
     let  hash = window.location.hash

     if (hash && hash.match(/^#doc-([0-9]{18})/)) {
       let matches = hash.match(/^#doc-([0-9]{18})/);
       let id = matches[1];
       let elem = document.getElementById("available_button-" + id)
       if (elem) {
         elem.click();
       }
       return id;
     }
   }

   /**
    * Waits for element with id #request-url-data-<id> to appear.
    *
    * Returns a promise for the id passed in.
    */
   function waitForRequestUrlData(id) {
     return waitForElementById("request-url-data-" + id)
     .then(_ => { return id })
   }

   /**
    * Continuously checks if an element exists then resolves.
    */
   async function waitForElementById(id) {
     while(!document.getElementById(id)) {
       // Hack that is supposedly better than SetTimeout
       // https://stackoverflow.com/a/47776379/256854
       await new Promise( resolve =>  requestAnimationFrame(resolve) )
     }
   };

   /**
    * Clicks the request button associated with id.
    *
    * Returns the id passed in.
    */
   function clickRequestButton(id) {
     let elem = document.getElementById("request-btn-" + id)

     if (elem) {
       elem.click();
     }
     return id;
   }

 /**
  * Periodically checks for all AJAX availability requests to finish, then displays
  * messages for records that we couldn't load availability info for.
  */
 BlacklightAlma.prototype.checkAndPopulateMissing = function() {

     var baObj = this;
     for(key in baObj.availabilityRequestsFinished) {
         if(!baObj.availabilityRequestsFinished[key]) {

             setTimeout(function() { baObj.checkAndPopulateMissing(); }, 1000);
             return;
         }
     }

     $(".availability-ajax-load").filter(function(index, element) {
         return ! $(element).hasClass("availability-ajax-loaded");
     }).each(function (index, element) {
        noHoldingsAvailabilityButton($(element).data("availabilityIds"));
        $(element).html("<span style='color: red'>No status available for this item</span>");
     });
 };
