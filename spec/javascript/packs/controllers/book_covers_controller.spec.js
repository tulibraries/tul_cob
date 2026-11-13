import { Application } from "@hotwired/stimulus"
import BookCoversController from "controllers/book_covers_controller"

describe("BookCoversController", () => {
  let application
  let request
  let ajaxSpy

  const flush = () => new Promise(resolve => setTimeout(resolve, 0))

  beforeEach(() => {
    request = { done: jest.fn().mockReturnThis(), abort: jest.fn() }
    ajaxSpy = jest.spyOn($, "ajax").mockReturnValue(request)

    document.body.innerHTML = `
      <div id="covers-root" data-controller="book-covers">
        <div class="thumbnail" data-isbn="9780000000001">
          <img class="book_cover invisible" src="">
        </div>
      </div>
    `
  })

  afterEach(() => {
    if (application) application.stop()
    application = null
    ajaxSpy.mockRestore()
    document.body.innerHTML = ""
  })

  const startController = async () => {
    application = Application.start()
    application.register("book-covers", BookCoversController)
    await flush()
  }

  it("requests covers for the thumbnails on connect", async () => {
    await startController()

    expect(ajaxSpy).toHaveBeenCalledTimes(1)
    expect(ajaxSpy.mock.calls[0][0].url).toContain("ISBN:9780000000001")
    expect(request.abort).not.toHaveBeenCalled()
  })

  it("aborts the cover request when disconnected", async () => {
    await startController()

    document.getElementById("covers-root").remove()
    await flush()

    expect(request.abort).toHaveBeenCalledTimes(1)
  })
})
