import { Application } from "@hotwired/stimulus"
import TomSelectController from "controllers/tom_select_controller"

const settle = () => new Promise(resolve => setTimeout(resolve, 0))

describe("TomSelectController", () => {
  let application
  let select

  beforeEach(async () => {
    document.body.innerHTML = `
      <form>
        <label for="format">Resource Type</label>
        <select id="format" name="f[format][]" multiple data-controller="tom-select">
          <option value="Book" selected>Book</option>
          <option value="Journal">Journal</option>
        </select>
      </form>
    `
    select = document.getElementById("format")
    application = Application.start()
    application.register("tom-select", TomSelectController)
    await settle()
  })

  afterEach(async () => {
    document.body.innerHTML = ""
    await settle()
    application.stop()
  })

  it("submits selected filters through the original select", () => {
    expect(select.tomselect.items).toEqual(["Book"])
    select.tomselect.addItem("Journal")

    expect(new FormData(document.querySelector("form")).getAll("f[format][]"))
      .toEqual(["Book", "Journal"])
    expect(document.querySelector("label").htmlFor).toBe(select.tomselect.control_input.id)
  })

  it("preserves changed filters and the dropdown label when caching and reconnecting", async () => {
    const label = document.querySelector("label")
    expect(select.tomselect.dropdown_content.getAttribute("aria-labelledby")).toBe(label.id)
    select.tomselect.setValue(["Journal"])
    document.dispatchEvent(new Event("turbo:before-cache"))

    expect(select.tomselect).toBeUndefined()
    expect(document.querySelector(".ts-wrapper")).toBeNull()
    expect(Array.from(select.selectedOptions, option => option.value)).toEqual(["Journal"])
    expect(label.htmlFor).toBe(select.id)

    select.removeAttribute("data-controller")
    await settle()
    select.setAttribute("data-controller", "tom-select")
    await settle()

    expect(select.tomselect.items).toEqual(["Journal"])
    expect(document.querySelectorAll(".ts-wrapper")).toHaveLength(1)
    expect(label.htmlFor).toBe(select.tomselect.control_input.id)
    expect(label.id).not.toBe("")
    expect(select.tomselect.dropdown_content.getAttribute("aria-labelledby")).toBe(label.id)
  })

  it("only selects highlighted options on Enter and leaves Tab unhandled", async () => {
    const control = select.tomselect
    control.clear()
    control.focus()
    await settle()
    control.open()

    const press = (key, keyCode) => {
      const event = new KeyboardEvent("keydown", {
        key, keyCode, bubbles: true, cancelable: true
      })
      control.control_input.dispatchEvent(event)
      return event
    }

    const firstValue = control.activeOption.dataset.value
    press("ArrowDown", 40)
    expect(control.activeOption.dataset.value).not.toBe(firstValue)
    press("ArrowUp", 38)
    expect(control.activeOption.dataset.value).toBe(firstValue)
    expect(control.items).toEqual([])
    expect(press("Tab", 9).defaultPrevented).toBe(false)
    expect(Array.from(select.selectedOptions)).toEqual([])

    press("Enter", 13)
    expect(control.items).toEqual([firstValue])
    press("ArrowDown", 40)
    expect(control.activeOption.dataset.value).not.toBe(firstValue)
    expect(press("Tab", 9).defaultPrevented).toBe(false)
    expect(new FormData(document.querySelector("form")).getAll("f[format][]"))
      .toEqual([firstValue])
  })

  it("deletes the last selected filter when Delete is pressed after the items", () => {
    const control = select.tomselect
    control.addItem("Journal")
    control.setCaret(control.items.length)
    control.control_input.dispatchEvent(new KeyboardEvent("keydown", {
      key: "Delete", keyCode: 46, bubbles: true, cancelable: true
    }))

    expect(control.items).toEqual(["Book"])
  })

  it("keeps selected filters when Delete is pressed while editing a query", () => {
    const control = select.tomselect
    control.setTextboxValue("Book")
    control.control_input.dispatchEvent(new KeyboardEvent("keydown", {
      key: "Delete", keyCode: 46, bubbles: true, cancelable: true
    }))

    expect(control.items).toEqual(["Book"])
  })
})
