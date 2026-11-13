import "legacy/application"

describe("legacy application delegated handlers", () => {
  beforeAll(() => {
    $.fn.tooltip = jest.fn()
  })

  afterAll(() => {
    delete $.fn.tooltip
  })

  afterEach(() => {
    document.body.innerHTML = ""
  })

  it("marks a header link active when it is added after the module loads", () => {
    document.body.innerHTML = `
      <nav>
        <a class="header-links active" id="first">First</a>
        <a class="header-links" id="second">Second</a>
      </nav>
    `

    document.getElementById("second").click()

    expect(document.getElementById("second").classList.contains("active")).toBe(true)
    expect(document.getElementById("first").classList.contains("active")).toBe(false)
  })

  it("highlights the subject hierarchy on hover for subjects added after the module loads", () => {
    document.body.innerHTML = `
      <div>
        <a class="search-subject" id="parent">Parent</a>
        <a class="search-subject" id="child">Child</a>
      </div>
    `
    const parent = document.getElementById("parent")
    const child = document.getElementById("child")

    child.dispatchEvent(new MouseEvent("mouseover", { bubbles: true, relatedTarget: document.body }))
    expect(parent.classList.contains("field-hierarchy")).toBe(true)

    child.dispatchEvent(new MouseEvent("mouseout", { bubbles: true, relatedTarget: document.body }))
    expect(parent.classList.contains("field-hierarchy")).toBe(false)
  })

  it("toggles the facet filter icon once per click", () => {
    document.body.innerHTML = `
      <button id="facet-filter-icon"><span id="facet-icons" class="remove-facet-icon"></span></button>
    `
    const icons = document.getElementById("facet-icons")

    document.getElementById("facet-filter-icon").click()
    expect(icons.classList.contains("open-facet-icon")).toBe(true)
    expect(icons.classList.contains("remove-facet-icon")).toBe(false)

    document.dispatchEvent(new Event("turbo:load"))
    document.getElementById("facet-filter-icon").click()
    expect(icons.classList.contains("open-facet-icon")).toBe(false)
    expect(icons.classList.contains("remove-facet-icon")).toBe(true)
  })
})
