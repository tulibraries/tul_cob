$(document).ready(function(){

	var tracks = [
		{id: "header-logo", category: "navigation"},
		{id: "login", category: "navigation"},
		{id: "logout", category: "navigation"},
		{id: "bookmarks", category: "navigation"},
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
		{id: "bookmarks", category: "search-results"},
		{id: "direct_link_online", category: "search-results"},
		{id: "single_link_online", category: "search-results"},
		{id: "many_links_online", category: "search-results"},
		{id: "online-only", category: "search-results"},
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
	];

	tracks.forEach(function(track) {
		if (el = document.getElementById(track.id)) {
			alert(track.id + " " + track.category);
			el.addEventListener("click", function(){
		    handleEventClicks(track.id, track.category) })
			}
		});	

});
