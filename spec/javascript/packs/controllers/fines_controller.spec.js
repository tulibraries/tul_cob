import { Application } from "@hotwired/stimulus"
import FinesController from "controllers/fines_controller"

describe("FinesController", () => {
  let application

  const flush = () => new Promise(resolve => setTimeout(resolve, 0))

  const setupDom = () => {
    document.head.innerHTML = `<meta name="csrf-token" content="foo">`
    document.body.innerHTML = `
      <div id="container">
        <div id="fines-root" data-controller="fines" data-fines-url="/users/fines">
          <div data-fines-target="spinner" class="spinner">Loading</div>
          <table><tbody data-fines-target="table"></tbody></table>
        </div>
      </div>
    `
  }

  const startController = async () => {
    application = Application.start()
    application.register("fines", FinesController)
    await flush()
  }

  const deferredResponse = () => {
    let resolveResponse
    fetch.mockResponseOnce(() => new Promise(resolve => { resolveResponse = resolve }))
    return (body) => resolveResponse(body)
  }

  beforeEach(() => {
    fetch.resetMocks()
    setupDom()
  })

  afterEach(() => {
    if (application) application.stop()
    application = null
    document.body.innerHTML = ""
  })

  it("loads fines into the table on connect", async () => {
    fetch.mockResponseOnce("<tr><td>Overdue fine</td></tr>")

    await startController()
    await flush()

    expect(fetch).toHaveBeenCalledTimes(1)
    expect(fetch.mock.calls[0][1].signal).toBeInstanceOf(AbortSignal)
    expect(document.querySelector('[data-fines-target="table"]').textContent).toContain("Overdue fine")
    expect(document.querySelector(".spinner")).toBeNull()
  })

  it("aborts the request and leaves the page untouched when disconnected mid-request", async () => {
    const respond = deferredResponse()

    await startController()
    const root = document.getElementById("fines-root")
    const table = root.querySelector('[data-fines-target="table"]')
    const signal = fetch.mock.calls[0][1].signal

    root.remove()
    await flush()

    expect(signal.aborted).toBe(true)

    respond("<tr><td>Late response</td></tr>")
    await flush()

    expect(table.innerHTML).toBe("")
    expect(root.querySelector(".spinner")).not.toBeNull()
  })

  it("does not fetch again when reconnected after a successful load", async () => {
    fetch.mockResponseOnce("<tr><td>Overdue fine</td></tr>")

    await startController()
    await flush()

    const root = document.getElementById("fines-root")
    root.remove()
    await flush()
    document.getElementById("container").appendChild(root)
    await flush()

    expect(fetch).toHaveBeenCalledTimes(1)
    expect(root.querySelector('[data-fines-target="table"]').textContent).toContain("Overdue fine")
  })

  it("fetches again when reconnected after an aborted load", async () => {
    deferredResponse()

    await startController()

    const root = document.getElementById("fines-root")
    root.remove()
    await flush()

    fetch.mockResponseOnce("<tr><td>Second attempt</td></tr>")
    document.getElementById("container").appendChild(root)
    await flush()
    await flush()

    expect(fetch).toHaveBeenCalledTimes(2)
    expect(root.querySelector('[data-fines-target="table"]').textContent).toContain("Second attempt")
  })
})
