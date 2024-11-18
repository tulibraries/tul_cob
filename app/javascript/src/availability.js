

$(document).on('turbo:load', function() {
	const ba_object = require("./blacklight_alma_lib")
    const ba = new ba_object
		console.log(ba)
    ba.loadAvailability();
});

(function(){
	  $.fn.longList = function() {

	    return this.each(function(){
	      var $list = $(this),
	      $children = $list.children().filter(function(i){
	        return $(this);
	      }),
	      type = $list.data("list-type"),
	      $more = $('<button class="btn bg-white text-cherry-red border border-light-grey m-0 show-all">Show All<span class="visually-hidden"> at ' + type + '</span></button>'),
	      $less = $('<button class="btn bg-white text-cherry-red border border-light-grey m-0 show-less">Show Less<span class="visually-hidden"> at ' + type + '</span></button>');

	      init();

	      function init(){
	        if ($children.length > 5){
	          $children.hide().slice(0,5).show();
	          $more.on('click', function(e){
	            e.preventDefault();
	            $children.fadeIn();
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

	})(jQuery);

	Blacklight.onLoad(function() {
	  $('[data-long-list]').longList();
	});
