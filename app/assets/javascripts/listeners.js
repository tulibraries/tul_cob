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
			{id: "navbar_more", category: "navigation"},
			{id: "navbar_articles", category: "navigation"},
			{id: "navbar_databases", category: "navigation"},
			{id: "navbar_journals", category: "navigation"},
			{id: "navbar_website", category: "navigation"},
			{id: "startOverLink", category: "search-results"},
			{id: "start_over", category: "record-page"},
			{id: "back_to_search", category: "search-results"},
			{id: "advanced-search-submit", category: "search-results"},
			{id: "articles_advanced_search", category: "search-results"},
			{id: "databases_advanced_search", category: "search-results"},
			{id: "journals_advanced_search", category: "search-results"},
			{id: "catalog_advanced_search", category: "search-results"},
			{id: "search", category: "search-results"},
			{id: "bento_books_and_media", category: "bento-results"},
			{id: "bento_articles", category: "bento-results"},
			{id: "bento_databases", category: "bento-results"},
			{id: "bento_website", category: "bento-results"},
			{id: "bento_journals", category: "bento-results"},
			{id: "bento_resource_types", category: "bento-results"},
			{id: "emailLink", category: "record-page"},
			{id: "smsLink", category: "record-page"},
			{id: "refworksLink", category: "record-page"},
			{id: "citationLink", category: "record-page"},
			{id: "risLink", category: "record-page"},
			{id: "bookmark_button", category: "record-page"},
			{class: "bento-online", category: "bento-results"},
			{class: "online-btn", category: "search-results"},
			{class: "request-button", category: "search-results"},
			{class: "availability-btn", category: "search-results"},
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
