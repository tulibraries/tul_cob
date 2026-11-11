
import { Application } from "@hotwired/stimulus"
import CitationCopyController from "controllers/citation_copy_controller"

describe("CitationCopyController", () => {
  let application
  let originalClipboard
  let originalClipboardItem
  let originalSecureContext

  beforeEach(() => {
    originalClipboard = Object.getOwnPropertyDescriptor(navigator, "clipboard")
    originalClipboardItem = global.ClipboardItem
    originalSecureContext = Object.getOwnPropertyDescriptor(window, "isSecureContext")

    Object.defineProperty(window, "isSecureContext", {
      configurable: true,
      value: true
    })

    document.body.innerHTML = `
      <div data-controller="citation-copy">
        <button data-action="click->citation-copy#copy">Copy</button>
        <div data-citation-copy-target="content">
          <p>Smith, J. (2024). <em>Example book title</em>. Publisher.</p>
        </div>
      </div>
    `
  })

  afterEach(() => {
    if (application) application.stop()
    application = null
    document.body.innerHTML = ""

    if (originalClipboard) {
      Object.defineProperty(navigator, "clipboard", originalClipboard)
    } else {
      delete navigator.clipboard
    }

    if (originalClipboardItem === undefined) {
      delete global.ClipboardItem
    } else {
      global.ClipboardItem = originalClipboardItem
    }

    if (originalSecureContext) {
      Object.defineProperty(window, "isSecureContext", originalSecureContext)
    } else {
      delete window.isSecureContext
    }

    jest.restoreAllMocks()
  })

  it("preserves italic formatting when copying a citation", async () => {
    const write = jest.fn().mockResolvedValue(undefined)

    Object.defineProperty(navigator, "clipboard", {
      configurable: true,
      value: { write, writeText: jest.fn() }
    })

    global.ClipboardItem = jest.fn().mockImplementation(data => ({ data }))

    application = Application.start()
    application.register("citation-copy", CitationCopyController)

    await new Promise(resolve => setTimeout(resolve, 0))

    const content = document.querySelector('[data-citation-copy-target="content"]')

    Object.defineProperty(content, "innerText", {
      configurable: true,
      get() {
        return this.textContent
      }
    })

    document.querySelector("button").click()

    await new Promise(resolve => setTimeout(resolve, 0))

    expect(write).toHaveBeenCalledTimes(1)

    const clipboardItem = write.mock.calls[0][0][0]

    expect(clipboardItem.data["text/html"]).toBeDefined()
    expect(clipboardItem.data["text/plain"]).toBeDefined()

    const readBlob = blob => new Promise((resolve, reject) => {
      const reader = new FileReader()
      reader.onload = () => resolve(reader.result)
      reader.onerror = () => reject(reader.error)
      reader.readAsText(blob)
    })

    const html = await readBlob(clipboardItem.data["text/html"])
    const text = await readBlob(clipboardItem.data["text/plain"])

    expect(html).toContain("<em>Example book title</em>")
    expect(text).toContain("Example book title")
    expect(text).not.toContain("<em>")
  })

  it("falls back to plain text when rich-text copying fails", async () => {
    const write = jest.fn().mockRejectedValue(new Error("Clipboard write failed"))
    const writeText = jest.fn().mockResolvedValue(undefined)
    Object.defineProperty(navigator, "clipboard", {
      configurable: true,
      value: { write, writeText }
    })
    global.ClipboardItem = jest.fn().mockImplementation(data => ({ data }))
    jest.spyOn(console, "warn").mockImplementation(() => {})
    application = Application.start()
    application.register("citation-copy", CitationCopyController)
    await new Promise(resolve => setTimeout(resolve, 0))
    const content = document.querySelector('[data-citation-copy-target="content"]')
    Object.defineProperty(content, "innerText", {
      configurable: true,
      get() {
        return this.textContent
      }
    })
    document.querySelector("button").click()
    await new Promise(resolve => setTimeout(resolve, 0))
    expect(write).toHaveBeenCalledTimes(1)
    expect(writeText).toHaveBeenCalledWith(
      "Smith, J. (2024). Example book title. Publisher."
    )
  })

  it("preserves paragraph boundaries and italics when copying grouped citations", async () => {
    const write = jest.fn().mockResolvedValue(undefined)

    Object.defineProperty(navigator, "clipboard", {
      configurable: true,
      value: { write, writeText: jest.fn() }
    })

    global.ClipboardItem = jest.fn().mockImplementation(data => ({ data }))

    const content = document.querySelector('[data-citation-copy-target="content"]')
    content.innerHTML = `
      <p>Smith, J. (2024). <em>First book</em>. Publisher.</p>
      <p>Jones, A. (2023). <em>Second book</em>. Publisher.</p>
    `

    Object.defineProperty(content, "innerText", {
      configurable: true,
      get() {
        return this.textContent
      }
    })

    application = Application.start()
    application.register("citation-copy", CitationCopyController)

    await new Promise(resolve => setTimeout(resolve, 0))

    document.querySelector("button").click()

    await new Promise(resolve => setTimeout(resolve, 0))

    expect(write).toHaveBeenCalledTimes(1)

    const clipboardItem = write.mock.calls[0][0][0]
    const readBlob = blob => new Promise((resolve, reject) => {
      const reader = new FileReader()
      reader.onload = () => resolve(reader.result)
      reader.onerror = () => reject(reader.error)
      reader.readAsText(blob)
    })

    const html = await readBlob(clipboardItem.data["text/html"])

    const copied = document.createElement("div")
    copied.innerHTML = html

    const paragraphs = copied.querySelectorAll("p")

    expect(paragraphs).toHaveLength(2)
    expect(paragraphs[0].querySelector("em").textContent).toBe("First book")
    expect(paragraphs[1].querySelector("em").textContent).toBe("Second book")
  })
})
