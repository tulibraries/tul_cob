import { Application } from 'stimulus';
import AvailabilityController from 'controllers/availability_controller'

describe('AvailabilityController', () => {
  const controller = `
    <div data-controller="availability" data-availability-url="http://localhost:32770/almaws/item/991030169919703811?redirect_to=http%3A%2F%2Flocalhost%3A32770%2F%3Ff%255Bavailability_facet%255D%255B%255D%3DAt%2Bthe%2BLibrary">
      <div class="controls">
        <button data-action="availability#item" data-availability-ids="991030169919703811" class="btn btn-sm btn-default availability-toggle-details" data-toggle="collapse" data-target="#physical-document-1, availability.button" id="available_button-1">
          <span role="spin" aria-expanded="false">Loading...</span>
        </button>
        <div data-target="availability.spinner" class="spinner">
          <span class="glyphicon glyphicon-refresh glyphicon-spin"></span>
          Loading Availability
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
          expect(els.length).toEqual(0)
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

    test('panel target unhidden', () => {
      let hidden = $('div[data-target="availability.panel"]')
      .parent().hasClass("hidden")

      expect(hidden).toEqual(false)
    });

    test('request target is unhidden', () => {
      let hidden = $('#requests-container-991030169919703811')
      .hasClass("hidden")

      expect(hidden).toEqual(false)
    });

    test('request target gets tagged with search-results-request-btn', () => {
      let tagged = $('#requests-container-991030169919703811')
      .hasClass('search-results-request-btn')

      expect(tagged).toEqual(true)
    });
  });
});
