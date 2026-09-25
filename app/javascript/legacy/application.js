$(window).on('turbo:load', function() {
	window.onload= function(){
		// This fixes a bug where the pages are loading at the bottom in Chrome
		if(location.hash == undefined || location.hash == "" ) {
			parent.window.scrollTo(0,0);
		}
	}

	if ($(window).width() < 768) {
		$('#nav-tools').insertAfter('#document');
		$('#facet-filter-icon').removeClass('hidden');
		$('#facet-panel-collapse').removeClass('show');
		$('.small-limit-search-heading').removeClass('d-none');
	}
	else {
		$('#nav-tools').insertAfter('#page-links');
		$('#facet-filter-icon').addClass('hidden');
    $('#facet-availability_facet-header').removeClass('collapsed')
	}
});

const adjustSecondaryFields = function() {
	$(".secondary-dl").children("dt").removeClass("col-sm-3 col-md-3").addClass("col-sm-2 col-md-2");
	$(".secondary-dl").children("dd").addClass("ps-md-3");
};

$(document).on("turbo:load", adjustSecondaryFields);

$(document).ready(function() {
	$("body").tooltip({
    selector: '[data-bs-toggle="tooltip"]'
  });

	$('.decorative').each(function() {
    $(this).attr('alt', "");
  });

	// This is necessary because iOS is triggering the resize event when an element is clicked.
	// More information about this solution can be found here: https://stackoverflow.com/a/24212316/256854

  var origWindowWidth = $(window).width();
  $(window).on('resize', function() {
    var windowWidth = $(window).width();

    // ShortCircuit if this is not a real resize.
    if (windowWidth == origWindowWidth) {
      return;
    }

    if (windowWidth < 768) {
	  $('#nav-tools').insertAfter('#document');
	  $('#facet-filter-icon').removeClass('hidden');
    $('#facet-panel-collapse').removeClass('show');
	  $('.limit-search-heading').addClass('d-none');
    }
    else {
	  $('#nav-tools').insertAfter('#page-links');
	  $('#facet-filter-icon').addClass('hidden');
    $('#facet-panel-collapse').addClass('show');
    }
	});
});

$(document).on("turbo:load", function() {
  $(window).trigger("load.bs.select.data-api");
});

$(document).ready(function(){

  //link highlighting of hierarchy
  $(".search-subject").hover(
    function() {
      $(this).prevAll().addClass("field-hierarchy");
    },
    function() {
      $(this).prevAll().removeClass("field-hierarchy");
    }
  );
});

document.addEventListener("show.blacklight.blacklight-modal", function() {
	$(".request-btn, #citeLink").find("span.fa-spinner").remove();

	// This was added to stop the background from shifting when modals are opened
  const scrollbarWidth = window.innerWidth - document.documentElement.clientWidth;
  document.body.style.setProperty("--blacklight-modal-scrollbar-width", `${scrollbarWidth}px`);
  document.body.classList.add("blacklight-modal-open");
});

document.addEventListener("hide.blacklight.blacklight-modal", function() {
  document.body.classList.remove("blacklight-modal-open");
  document.body.style.removeProperty("--blacklight-modal-scrollbar-width");
});

$(document).on('turbo:load', function() {
	$(function () {
	  $('[data-bs-toggle="tooltip"]').tooltip()
	})

	if ($(".noresults").length >= 1) {
		$("#sortAndPerPage").remove();
		$("#documents").css("border", "none");
	}

	if ($("#search-navbar form").length == 0) {
		$("#search-navbar").css("padding-left", "15%");
	}

	$('#facet-filter-icon').click( function(){
    $(this).find('span#facet-icons').toggleClass('open-facet-icon').toggleClass('remove-facet-icon');
	});
 });

 $(".header-links").on("click", function(){
	 $(this).siblings().removeClass('active');
	$(this).addClass("active");
 });


window.toggle = function(x) {
	if (x == "secondary") {
	 document.getElementById("sub-toggler-icon").classList.toggle("change");
	}
	else if (x == "search") {
	 document.getElementById("search-toggler-icon").classList.toggle("change");
	}
	else {
		document.getElementById("main-toggler-icon").classList.toggle("change");
	}
};
