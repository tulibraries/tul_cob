// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, vendor/assets/javascripts,
// or any plugin's vendor/assets/javascripts directory can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// compiled file. JavaScript code in this file should be added after the last require_* statement.
//
// Read Sprockets README (https://github.com/rails/sprockets#sprockets-directives) for details
// about supported directives.
//
//= require jquery
//= require 'blacklight_advanced_search'
//= require rails-ujs
//= require popper
//= require twitter/typeahead

//= require bootstrap
//= require turbolinks//

// Required by Blacklight
//= require blacklight/blacklight

// For blacklight_range_limit built-in JS, if you don't want it you don't need
// this:
//= require 'blacklight_range_limit'

//= require sifter
//=require microplugin
//=require selectize

//= require_tree .

$(window).on('turbolinks:load', function() {
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

$(document).ready(function() {
	$("body").tooltip({
    selector: '[data-bs-toggle="tooltip"]'
  });

	$(".secondary-dl").children("dt").removeClass("col-sm-3 col-md-3").addClass("col-sm-2 col-md-2");
	$(".secondary-dl").children("dd").addClass("ps-md-3");

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

$(document).on('turbolinks:load', function() {
   $(window).trigger('load.bs.select.data-api');
   $(".selectize").selectize();
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

$(document).on('turbolinks:load', function() {
	$(function () {
 	  $('[data-bs-toggle="tooltip"]').tooltip()
 	})

	if ($(".noresults").length >= 1) {
		$("#sortAndPerPage").remove();
		$("#documents").css("border", "none");
	}

 	if ($("div.navbar-form").length == 0) {
 		$("#search-navbar").css("padding-left", "15%");
 	}

	$(".modal").on("show.bs.modal", function() {
		$(".request-btn").find("span").remove();
	})

	$('#facet-filter-icon').click( function(){
    $(this).find('span#facet-icons').toggleClass('open-facet-icon').toggleClass('remove-facet-icon');
	});
 });

 $(".header-links").on("click", function(){
	 $(this).siblings().removeClass('active');
	 $(this).addClass("active");
 });


 function toggle(x) {
	if (x == "secondary") {
	 document.getElementById("sub-toggler-icon").classList.toggle("change");
	}
	else if (x == "search") {
	 document.getElementById("search-toggler-icon").classList.toggle("change");
	}
	else {
		document.getElementById("main-toggler-icon").classList.toggle("change");
	}

}

// This hack helps with a race condition bug in blacklight_range_limit gem.
// REF: BL-1171 and project_blacklight/blacklight_range_limit#111
window.addEventListener('load', function(event) {
   $("#facet-pub_date_sort").trigger("shown.bs.collapse");
});

