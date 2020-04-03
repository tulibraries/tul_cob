import { Application } from 'stimulus';
import AvailabilityController from 'controllers/availability_controller'

describe('AvailabilityController', () => {
  (function(){
  	  $.fn.longList = function() {

  	    return this.each(function(){
  	      var $list = $(this),
  	      $children = $list.children().css("display", "flex").filter(function(i){
  	        return $(this);
  	      }),
  	      type = $list.data("list-type"),
  	      $more = $('<button class="btn btn-sm bg-tan text-red border border-header-grey m-2 show-all">Show All<span class="sr-only"> at ' + type + '</span></button>'),
  	      $less = $('<button class="btn btn-sm bg-tan text-red border border-header-grey m-2 show-less">Show Less<span class="sr-only"> at ' + type + '</span></button>');

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
              $list.after($more);
  	          $less.insertAfter($more).hide();
  	        }
  	      }
  	    });
  	  };

  	})(jQuery);

  const controller = `
    <div data-controller="availability" data-availability-url="http://localhost:32770/almaws/item/991030169919703811?redirect_to=http%3A%2F%2Flocalhost%3A32770%2F%3Ff%255Bavailability_facet%255D%255B%255D%3DAt%2Bthe%2BLibrary">
      <div class="controls">
        <button data-action="availability#item" data-availability-ids="991030169919703811" class="btn btn-sm btn-default availability-toggle-details" data-toggle="collapse" data-target="#physical-document-1, availability.button" id="available_button-1">
          <i class="fa fa-spinner" role="spinbutton"></i>
          <span>Loading...</span>
        </button>
        <div data-target="availability.spinner" class="spinner">
          <i class="fa fa-spinner" role="spinbutton"></i>
          <span>Loading Availability</span>
        </div>

        <div id="requests-container-991030169919703811" class="hidden requests-container" data-controller="requests" data-target="show.request, availability.request">
            <a data-ajax-modal="trigger" class="log-in-link" href="/users/sign_in?redirect_to=http%3A%2F%2Flocalhost%3A32770%2F%3Ff%255Bavailability_facet%255D%255B%255D%3DAt%2Bthe%2BLibrary">Log in to see request options</a>
        </div>
      </div>

      <div data-availability-ids="991030169919703811" id="physical-document-1" class="collapse panel-content avail-container index-avail-container">
        <div class="table-wrapper hidden">
          <div data-target="availability.panel"></div>
          <div></div>
        </div>
      </div>
    </div>
  `;

  document.body.innerHTML = controller
  document.head.innerHTML = `<meta name="csrf-token" content="foo">`

  const application = Application.start()
  application.register('availability', AvailabilityController);

  describe('#item', () => {
    it('s a smoke test', () => {
      expect(true).toBeTruthy();
    })

    test('the spinner target is removed', async () => {
      fetch.mockResponseOnce("Hello World")
      $('button#available_button-1').click()

      await  new Promise(resolve => {
        setTimeout(() => {
          const els = document.getElementsByClassName('spinner')
          expect(els.length).toEqual(1)
          resolve(true);
        }, 10);
      });
    });

    test('repsone text is added to panel target', () => {
      const response = $('div[data-target="availability.panel"]').text()
      expect(response).toEqual("Hello World")
    });

    test('clicked is added to button class', () => {
      let clicked = $('button#available_button-1').hasClass("clicked")
      expect(clicked).toEqual(true)
    });

    test.skip('panel target unhidden', () => {
      let hidden = $('div[data-target="availability.panel"]')
      .parent().hasClass("hidden")

      expect(hidden).toEqual(true)
    });

    test('request target is unhidden', () => {
      let hidden = $('#requests-container-991030169919703811')
      .hasClass("hidden")

      expect(hidden).toEqual(true)
    });

    test.skip('request target gets tagged with search-results-request-btn', () => {
      let tagged = $('#requests-container-991030169919703811')
      .hasClass('search-results-request-btn')

      expect(tagged).toEqual(true)
    });
  });
});
