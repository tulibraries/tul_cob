import { Application } from "@hotwired/stimulus"
import LoansController from "controllers/loans_controller"

describe("LoansController sorting", () => {
  let application

  const setupDom = () => {
    document.body.innerHTML = `
      <div id="loans-root" data-controller="loans">
        <table>
          <thead>
            <tr>
              <th data-loans-sort-key="title" data-sort-state="none" aria-sort="none">
                <button type="button" data-action="click->loans#toggleSort" data-sort-key="title">Title</button>
              </th>
              <th data-loans-sort-key="call_number" data-sort-state="none" aria-sort="none">
                <button type="button" data-action="click->loans#toggleSort" data-sort-key="call_number">Call Number</button>
              </th>
              <th data-loans-sort-key="due" data-sort-state="none" aria-sort="none">
                <button type="button" data-action="click->loans#toggleSort" data-sort-key="due">Due</button>
              </th>
            </tr>
          </thead>
          <tbody data-loans-target="table">
            <tr data-row="1">
              <td data-sort-key="title" data-sort-value="Gamma">Gamma</td>
              <td data-sort-key="call_number" data-sort-value="C10">C10</td>
              <td data-sort-key="due" data-sort-value="2026-01-10">01/10/2026</td>
            </tr>
            <tr data-row="2">
              <td data-sort-key="title" data-sort-value="Alpha">Alpha</td>
              <td data-sort-key="call_number" data-sort-value="A2">A2</td>
              <td data-sort-key="due" data-sort-value="2026-01-05">01/05/2026</td>
            </tr>
            <tr data-row="3">
              <td data-sort-key="title" data-sort-value="Beta">Beta</td>
              <td data-sort-key="call_number" data-sort-value="B1">B1</td>
              <td data-sort-key="due" data-sort-value="2026-01-08">01/08/2026</td>
            </tr>
            <tr>
              <td class="submit">Renew Selected</td>
            </tr>
          </tbody>
        </table>
      </div>
    `
  }

  const startController = async () => {
    application = Application.start()
    application.register("loans", LoansController)
    await new Promise(resolve => setTimeout(resolve, 0))
    return application
  }

  const currentOrder = (key) => {
    const rows = document.querySelectorAll('tbody[data-loans-target="table"] tr')
    return Array.from(rows)
      .filter((row) => !row.querySelector("td.submit"))
      .map((row) => row.querySelector(`[data-sort-key="${key}"]`).dataset.sortValue)
  }

  const clickSort = (key) => {
    document.querySelector(`button[data-sort-key="${key}"]`).click()
  }

  afterEach(() => {
    if (application) application.stop()
    application = null
    document.body.innerHTML = ""
  })

  it("sorts by title ascending", async () => {
    setupDom()
    await startController()

    clickSort("title")

    expect(currentOrder("title")).toEqual(["Alpha", "Beta", "Gamma"])
    expect(document.querySelector('th[data-loans-sort-key="title"]').getAttribute("aria-sort")).toBe("ascending")
  })

  it("sorts by call number ascending", async () => {
    setupDom()
    await startController()

    clickSort("call_number")

    expect(currentOrder("call_number")).toEqual(["A2", "B1", "C10"])
    expect(document.querySelector('th[data-loans-sort-key="call_number"]').getAttribute("aria-sort")).toBe("ascending")
  })

  it("sorts by due date ascending then descending", async () => {
    setupDom()
    await startController()

    clickSort("due")
    expect(currentOrder("due")).toEqual(["2026-01-05", "2026-01-08", "2026-01-10"])

    clickSort("due")
    expect(currentOrder("due")).toEqual(["2026-01-10", "2026-01-08", "2026-01-05"])
    expect(document.querySelector('th[data-loans-sort-key="due"]').getAttribute("aria-sort")).toBe("descending")
  })
})

describe("LoansController renewal", () => {
  let application

  const flush = () => new Promise(resolve => setTimeout(resolve, 0))

  beforeEach(() => {
    fetch.resetMocks()
    document.head.innerHTML = `<meta name="csrf-token" content="foo">`
    document.body.innerHTML = `
      <div id="loans-root" data-controller="loans">
        <div id="renewal-warning" style="display: none"></div>
        <form id="renew-form" action="/users/renew_selected" data-action="submit->loans#renewSelected">
          <input type="checkbox" name="loan_ids[]" value="1" checked>
          <input type="checkbox" id="checkall">
          <button type="submit" id="renew_selected">Renew Selected</button>
        </form>
      </div>
    `
  })

  afterEach(() => {
    if (application) application.stop()
    application = null
    document.body.innerHTML = ""
  })

  const startController = async () => {
    application = Application.start()
    application.register("loans", LoansController)
    await flush()
  }

  const submitForm = () => {
    document.getElementById("renew-form").dispatchEvent(new Event("submit", { bubbles: true, cancelable: true }))
  }

  it("shows an error when the renewal request fails", async () => {
    fetch.mockRejectOnce(new Error("Network down"))

    await startController()
    submitForm()
    await flush()

    const warning = document.getElementById("renewal-warning")
    expect(warning.textContent).toContain("could not process your renewal request")
    expect(warning.style.display).toBe("block")
  })

  it("does not show an error when disconnected mid-renewal", async () => {
    let resolveResponse
    fetch.mockResponseOnce(() => new Promise(resolve => { resolveResponse = resolve }))

    await startController()
    submitForm()

    const root = document.getElementById("loans-root")
    const warning = root.querySelector("#renewal-warning")
    const signal = fetch.mock.calls[0][1].signal

    root.remove()
    await flush()

    expect(signal.aborted).toBe(true)

    resolveResponse(JSON.stringify([{ loan_id: "1", renewed: true, due_date_display: "01/01/2027" }]))
    await flush()

    expect(warning.textContent).toBe("")
    expect(warning.style.display).toBe("none")
  })
})
