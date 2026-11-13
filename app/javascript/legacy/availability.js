import $ from "jquery"
import Core from "blacklight-frontend"

let almaIntegration = null;

const cancelAlmaIntegration = function() {
    almaIntegration?.cancel();
    almaIntegration = null;
};

$(document).on("turbo:visit", cancelAlmaIntegration);

$(document).on('turbo:load', function() {
    cancelAlmaIntegration();

    if (typeof window.AlmaIntegration === "undefined") {
        return;
    }

    if ($(".availability-ajax-load").length === 0 || $("#alma_availability_url").length === 0) {
        return;
    }

    almaIntegration = new window.AlmaIntegration();
    almaIntegration.loadAvailability();
});

(function(){
	  $.fn.longList = function() {

	    return this.each(function(){
	      var $list = $(this),
	      $children = $list.children().filter(function(i){
	        return $(this);
	      }),
	      type = $list.data("list-type"),
	      $more = $('<button class="btn bg-white text-cherry-red border border-light-grey m-0 show-all">Show All<span class="sr-only"> at ' + type + '</span></button>'),
	      $less = $('<button class="btn bg-white text-cherry-red border border-light-grey m-0 show-less">Show Less<span class="sr-only"> at ' + type + '</span></button>');

	      init();

	      function init(){
	        if ($children.length > 5){
	          $children.hide().slice(0,5).show();
	          $more.on('click', function(e){
	            e.preventDefault();
							$children.hide().slice(0,10000).show();
	            // $children.all.fadeIn();
	            $more.hide();
	            $less.fadeIn();
	          });
	          $less.on('click', function(e){
	            e.preventDefault();
	            $children.hide().slice(0,5).show();
	            $less.hide();
	            $more.fadeIn();
	          });
            $list.append($more);
	          $less.insertAfter($more).hide();
	        }
	      }
	    });
	  };

	})($);

	Core.onLoad(function() {
	  $('[data-long-list]').longList();
	});
