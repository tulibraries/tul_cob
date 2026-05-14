import { Application } from "@hotwired/stimulus"
import RequestFormController from "controllers/request_form_controller"

describe("RequestFormController", () => {
  let application

  const setupDom = () => {
    document.body.innerHTML = `
      <div id="request-form-root" data-controller="request-form">
        <select id="material_type">
          <option value="">Select a format</option>
          <option value="Book">Book</option>
        </select>

        <select data-request-form-target="descriptions">
          <optgroup label="Book">
            <option value="c. 3">c. 3</option>
            <option value="">any available copy</option>
          </optgroup>
        </select>

        <select data-request-form-target="pickups">
          <optgroup label="c. 3">
            <option value="MAIN">Charles Library</option>
          </optgroup>
        </select>

        <select id="hold_description">
          <option value="" selected>c. 3</option>
        </select>
      </div>
    `
  }

  const startController = async () => {
    application = Application.start()
    application.register("request-form", RequestFormController)
    await new Promise(resolve => setTimeout(resolve, 0))
  }

  afterEach(() => {
    if (application) application.stop()
    application = null
    window.item_level_descriptions = undefined
    window.item_level_pickup_locations = undefined
    document.body.innerHTML = ""
  })

  it("prepends a hidden disabled selected description placeholder when filtering by material type", async () => {
    setupDom()
    await startController()

    document.querySelector("#material_type").value = "Book"
    const root = document.getElementById("request-form-root")
    const controller = application.getControllerForElementAndIdentifier(root, "request-form")

    controller.typeSelect()

    const options = Array.from(root.querySelectorAll('[data-request-form-target="descriptions"] option'))

    expect(options[0].value).toBe("")
    expect(options[0].textContent).toBe("Select volume/issue or additional item details, if applicable")
    expect(options[0].disabled).toBe(true)
    expect(options[0].hidden).toBe(true)
    expect(options[1].textContent).toBe("c. 3")
    expect(options[2].textContent).toBe("any available copy")
  })

  it("prepends a hidden disabled selected pickup placeholder when filtering by description", async () => {
    setupDom()
    await startController()

    const root = document.getElementById("request-form-root")
    const controller = application.getControllerForElementAndIdentifier(root, "request-form")

    controller.select()

    const options = Array.from(root.querySelectorAll('[data-request-form-target="pickups"] option'))

    expect(options[0].value).toBe("")
    expect(options[0].disabled).toBe(true)
    expect(options[0].hidden).toBe(true)
    expect(options[1].textContent).toBe("Charles Library")
  })
})
