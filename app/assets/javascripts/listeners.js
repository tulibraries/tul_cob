$(document).ready(function(){

	var tracks = [
		{id: "header-logo", category: "navigation"},
		{id: "login", category: "navigation"},
		{id: "logout", category: "navigation"},
		{id: "bookmarks_nav", category: "navigation"},
		{id: "articles-header", category: "navigation"},
		{id: "articles-button", category: "navigation"},
		{id: "catalog-header", category: "navigation"},
		{id: "catalog-button", category: "navigation"},
		{id: "bento_books", category: "bento-results"},
		{id: "bento_articles", category: "bento-results"},
		{id: "bento_more", category: "bento-results"},
		{id: "bento_journals", category: "bento-results"},
		{id: "bento_resource_types", category: "bento-results"},
		{id: "one_online_button", category: "bento-results"},
		{id: "many_online_button", category: "bento-results"},
		{id: "advanced_search", category: "search-results"},
		{id: "basic_search", category: "search-results"},
		{id: "online_button", category: "search-results"},
		{id: "bookmark_button", category: "search-results"},
		{id: "direct_link_online", category: "search-results"},
		{id: "single_link_online", category: "search-results"},
		{id: "many_links_online", category: "search-results"},
		{id: "online_only", category: "search-results"},
		{id: "articles_basic_search", category: "search-results"},
		{id: "articles_advanced_search", category: "search-results"},
		{id: "back_to_search", category: "search-results"},
		{id: "start_over", category: "search-results"},
		{id: "emailLink", category: "search-results"},
		{id: "smsLink", category: "search-results"},
		{id: "refworksLink", category: "search-results"},
		{id: "citationLink", category: "search-results"},
		{id: "signin_for_request_options", category: "search-results"},
		{id: "request", category: "search-results"},
		{id: "available_button", category: "search-results"}
		{id: "navbar_everything", category: "navigation"}
		{id: "navbar_books", category: "navigation"}
		{id: "navbar_articles", category: "navigation"}
		{id: "navbar_journals", category: "navigation"}
		{id: "navbar_more", category: "navigation"}
		{id: "breadcrumbs_book", category: "navigation"}
		{id: "breadcrumbs_record", category: "navigation"}
		{id: "breadcrumbs_article", category: "navigation"}
		{id: "breadcrumbs_journal", category: "navigation"}
		{id: "request_options", category: "search-results"}
		{id: "request-btn-0", category: "search-results"}
	];

  function handleEventClicks(event) {
    if (typeof ga != "undefined") {
      ga('send', 'event', {
        eventCategory: 'Click Event',
        eventAction: 'click',
        eventLabel: event
      });
    }
  }

	tracks.forEach(function(track) {
		if (el = document.getElementById(track.id)) {
			el.addEventListener("click", function(){
		    handleEventClicks(track.id, track.category) })
			}
		});

});
