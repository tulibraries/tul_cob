import $ from "jquery"
import "legacy/alma_integration"

describe("AlmaIntegration cancellation", () => {
  let requests

  beforeEach(() => {
    jest.useFakeTimers()
    requests = []
    jest.spyOn($, "ajax").mockImplementation((url, options) => {
      const request = $.Deferred().promise({ url, options, abort: jest.fn() })
      requests.push(request)
      return request
    })

    document.body.innerHTML = `
      <div id="alma_availability_url" data-url="/almaws/item"></div>
      <div class="availability-ajax-load" data-availability-ids="111"></div>
      <div class="availability-ajax-load" data-availability-ids="222"></div>
    `
  })

  afterEach(() => {
    jest.restoreAllMocks()
    jest.useRealTimers()
    document.body.innerHTML = ""
  })

  it("aborts in-flight availability requests", () => {
    const alma = new window.AlmaIntegration()
    alma.loadAvailability()

    expect(requests).toHaveLength(1)

    alma.cancel()

    expect(requests[0].abort).toHaveBeenCalled()
  })

  it("does not retry a request that was aborted", () => {
    const alma = new window.AlmaIntegration()
    alma.loadAvailability()
    alma.cancel()

    requests[0].options.error({}, "abort", "abort")

    expect(requests).toHaveLength(1)
  })

  it("does not start new requests after cancel", () => {
    const alma = new window.AlmaIntegration()
    alma.loadAvailability()
    alma.cancel()

    alma.loadAvailabilityAjax("333", 1)

    expect(requests).toHaveLength(1)
  })

  it("stops polling for missing availability after cancel", () => {
    const alma = new window.AlmaIntegration()
    alma.loadAvailability()
    alma.cancel()

    jest.advanceTimersByTime(5000)

    expect($(".availability-ajax-load").first().html()).toBe("")
  })

  it("still retries requests that fail for other reasons", () => {
    const alma = new window.AlmaIntegration()
    alma.loadAvailability()

    requests[0].options.error({}, "error", "Internal Server Error")

    expect(requests).toHaveLength(2)
  })
})
