$(window).on('turbolinks:load', function() {
	const previews = document.getElementsByClassName("summary-previews");
	
	$(previews).each(function () {	
		let readLess = $('<a class="read-less">less</a>');
		let readMore = $('<a class="read-more">read more</a>');
	
		if ($(this).text().length > 300) {
				$(this).css("display", "-webkit-box").css("-webkit-box-orient", "vertical").css("-webkit-line-clamp", "2").css("margin-bottom", "0");
				$(readMore).insertAfter($(this));
				$(readLess).insertAfter($(this)).hide();
		}

		$(readMore).on("click", function () {
			$(this).hide();
			$(this).siblings("div.summary-previews").removeAttr("style");
			$(readLess).show();
		});
	
			$(readLess).on("click", function () {
			$(this).hide();
			$(readMore).removeAttr("style");
			$(this).prev("div").css("-webkit-box-orient", "vertical").css("-webkit-line-clamp", "2").css("margin-bottom", "0");
		});
	});
});