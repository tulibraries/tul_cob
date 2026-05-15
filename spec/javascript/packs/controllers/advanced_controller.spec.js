import { Application } from "@hotwired/stimulus"
import AdvancedController from "controllers/advanced_controller"

describe("AdvancedController", () => {
  let application

  const setupDom = () => {
    document.body.innerHTML = `
      <div
        data-controller="advanced"
        data-advanced-total-rows-value="3"
        data-advanced-visible-rows-value="2">
        <div data-advanced-target="row" data-row-index="1">
          <select id="f_1" class="advanced-search-options selectize" data-action="change->advanced#select" data-count="1">
            <option value="all_fields">All Fields</option>
            <option value="title">Title</option>
          </select>
          <select id="operator_q_1" name="operator[q_1]">
            <option value="contains">contains</option>
            <option value="begins_with">begins with</option>
          </select>
          <input type="text" id="q_1" value="cats">
        </div>

        <div data-advanced-target="boolean">
          <input type="radio" name="op_1" value="AND" checked>
          <input type="radio" name="op_1" value="OR">
        </div>

        <div data-advanced-target="row" data-row-index="2">
          <select id="f_2" class="advanced-search-options selectize" data-action="change->advanced#select" data-count="2">
            <option value="all_fields">All Fields</option>
            <option value="title">Title</option>
          </select>
          <select id="operator_q_2" name="operator[q_2]">
            <option value="contains">contains</option>
            <option value="begins_with">begins with</option>
          </select>
          <input type="text" id="q_2" value="dogs">
        </div>

        <div data-advanced-target="boolean">
          <input type="radio" name="op_2" value="AND" checked>
          <input type="radio" name="op_2" value="OR">
        </div>

        <div data-advanced-target="row" data-row-index="3">
          <select id="f_3" class="advanced-search-options selectize" data-action="change->advanced#select" data-count="3">
            <option value="all_fields">All Fields</option>
            <option value="title">Title</option>
          </select>
          <select id="operator_q_3" name="operator[q_3]">
            <option value="contains">contains</option>
            <option value="begins_with">begins with</option>
          </select>
          <input type="text" id="q_3" value="birds">
        </div>

        <div data-advanced-target="clauseInputs"></div>

        <button type="button" data-action="advanced#addRow" data-advanced-target="addButton">Add</button>
        <button type="button" data-action="advanced#removeRow" data-advanced-target="removeButton">Remove</button>
      </div>
    `
  }

  const startController = () => {
    application = Application.start()
    application.register("advanced", AdvancedController)
  }

  const controller = () => application.getControllerForElementAndIdentifier(document.querySelector("[data-controller='advanced']"), "advanced")

  afterEach(() => {
    if (application) application.stop()
    application = null
    document.body.innerHTML = ""
  })

  it("shows only the configured visible rows on connect", async () => {
    setupDom()
    startController()
    await new Promise(resolve => setTimeout(resolve, 0))

    const rows = document.querySelectorAll("[data-advanced-target='row']")
    const booleans = document.querySelectorAll("[data-advanced-target='boolean']")

    expect(rows[0].classList.contains("d-none")).toBeFalsy()
    expect(rows[1].classList.contains("d-none")).toBeFalsy()
    expect(rows[2].classList.contains("d-none")).toBeTruthy()
    expect(rows[2].querySelector("input").disabled).toBeTruthy()
    expect(booleans[0].classList.contains("d-none")).toBeFalsy()
    expect(booleans[1].classList.contains("d-none")).toBeTruthy()
  })

  it("adds and removes rows while clearing hidden values", async () => {
    setupDom()
    startController()
    await new Promise(resolve => setTimeout(resolve, 0))

    controller().addRow({ preventDefault() {} })

    const rows = document.querySelectorAll("[data-advanced-target='row']")
    expect(rows[2].classList.contains("d-none")).toBeFalsy()
    expect(rows[2].querySelector("input").disabled).toBeFalsy()

    controller().removeRow({ preventDefault() {} })

    expect(rows[2].classList.contains("d-none")).toBeTruthy()
    expect(rows[2].querySelector("#q_3").value).toBe("")
    expect(rows[2].querySelector("#operator_q_3").value).toBe("contains")
    expect(rows[2].querySelector("#f_3").value).toBe("all_fields")
  })

  it("only allows begins with for supported fields", async () => {
    setupDom()
    startController()
    await new Promise(resolve => setTimeout(resolve, 0))

    const field = document.getElementById("f_1")
    const operator = document.getElementById("operator_q_1")
    const beginsWith = operator.querySelector("option[value='begins_with']")

    expect(beginsWith.hidden).toBeTruthy()

    field.value = "title"
    controller().select({ currentTarget: field })

    expect(beginsWith.hidden).toBeFalsy()

    operator.value = "begins_with"
    field.value = "all_fields"
    controller().select({ currentTarget: field })

    expect(operator.value).toBe("contains")
    expect(beginsWith.hidden).toBeTruthy()
  })

  it("responds to the select change event", async () => {
    setupDom()
    startController()
    await new Promise(resolve => setTimeout(resolve, 0))

    const field = document.getElementById("f_1")
    const operator = document.getElementById("operator_q_1")
    const beginsWith = operator.querySelector("option[value='begins_with']")

    field.value = "title"
    field.dispatchEvent(new Event("change", { bubbles: true }))

    expect(beginsWith.hidden).toBeFalsy()
  })

  it("builds hidden clause inputs for visible populated rows", async () => {
    setupDom()
    startController()
    await new Promise(resolve => setTimeout(resolve, 0))

    const clauseInputs = document.querySelector("[data-advanced-target='clauseInputs']")
    const names = Array.from(clauseInputs.querySelectorAll("input")).map((input) => input.name)

    expect(names).toContain("clause[0][field]")
    expect(names).toContain("clause[0][query]")
    expect(names).toContain("clause[0][match]")
    expect(names).toContain("clause[1][field]")
    expect(names).toContain("clause[1][query]")
    expect(names).toContain("clause[1][match]")
    expect(names).toContain("clause[1][op]")
    expect(names).not.toContain("clause[2][field]")

    const operatorInput = clauseInputs.querySelector("input[name='clause[1][op]']")
    expect(operatorInput.value).toBe("must")
  })
})
