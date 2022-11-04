// This file configures the Google Analytics Tracking service.

$(document).ready(function(){
  setTimeout(function(){

    const tracks = [
      {id: "logo-navbar", category: "navigation"},
      {id: "my-account", category: "navigation"},
      {id: "my-account-mobile", category: "navigation"},
      {id: "login", category: "navigation"},
      {id: "logout", category: "navigation"},
      {id: "bookmarks_nav", category: "navigation"},
      {id: "navbar_everything", category: "navigation"},
      {id: "navbar_books_media", category: "navigation"},
      {id: "navbar_articles", category: "navigation"},
      {id: "navbar_databases", category: "navigation"},
      {id: "navbar_journals", category: "navigation"},
      {id: "navbar_website", category: "navigation"},
      {id: "startOverLink", category: "navigation"},
      {id: "start_over", category: "navigation"},
      {id: "back_to_search", category: "navigation"},
      {id: "login-mobile", category: "navigation"},
      {id: "advanced-search-submit", category: "search-results"},
      {id: "articles_advanced_search", category: "search-results"},
      {id: "databases_advanced_search", category: "search-results"},
      {id: "journals_advanced_search", category: "search-results"},
      {id: "catalog_advanced_search", category: "search-results"},
      {id: "search", category: "search-results"},
      {id: "bento_books_and_media_header", category: "bento-results"},
      {id: "bento_articles_header", category: "bento-results"},
      {id: "bento_databases_header", category: "bento-results"},
      {id: "bento_library_website_header", category: "bento-results"},
      {id: "bento_journals_header", category: "bento-results"},
      {id: "emailLink", category: "record-management"},
      {id: "smsLink", category: "record-management"},
      {id: "citationLink", category: "record-management"},
      {id: "risLink", category: "record-management"},
      {class: "toggle-bookmark", category: "record-management"},
      {id: "errorLink", category: "record-management"},
      {class: "query-list-title-link", category: "query-list"},
      {class: "query-list-view-more", category: "query-list"},
      {class: "query-list-online", category: "fulfillment"},
      {class: "bento-online", category: "fulfillment"},
      {class: "online-btn", category: "fulfillment"},
      {class: "search-results-request-btn", category: "fulfillment"},
      {class: "record-page-request-btn", category: "fulfillment"},
      {class: "request-btn", category: "fulfillment"},
      {class: "availability-btn", category: "fulfillment"},
      {class: "google-preview", category: "fulfillment"},
      {class: "hathitrust-link", category: "fulfillment"},
      {class: "libkey-btn", category: "fulfillment"},
      {class: "bento-libkey", category: "fulfillment"},
      {class: "pivot-top-level-expand", category: "search-results"},
      {class: "pivot-facet-outer", category: "search-results"},
      {class: "pivot-facet-inner", category: "search-results"},
      {class: "bento-full-results", category: "bento-results"},
      {class: "bento-online-results", category: "bento-results"},
    ];

    const handleEventClicks = (label, category) => {
      if (typeof ga != "undefined") {
        ga("send", "event", {
          eventCategory: category,
          eventAction: "click",
          eventLabel: label,
          forceSSL: true,
          anonymizeIp: true
        });
      };
    };

    tracks.forEach((track) => {
      if(track.id) {
        if (el = document.getElementById(track.id)) {
          el.addEventListener("click", () => {
            handleEventClicks(track.id, track.category)
          });
        };
      } else if (track.selector) {
        let elements = [... document.querySelectorAll(track.selector)]
        elements.forEach((el) => {
          el.addEventListener("click", () => {
            handleEventClicks(track.label, track.category)
          });
        });
      } else {
        let elements = [... document.getElementsByClassName(track.class)]
        elements.forEach((el) => {
          el.addEventListener("click", () => {
            handleEventClicks(track.class, track.category)
          });
        });
      };
    });

  },2000);
});
