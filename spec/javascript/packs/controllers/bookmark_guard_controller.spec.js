import { Application } from "@hotwired/stimulus"
import BookmarkGuardController from "controllers/bookmark_guard_controller"

describe("BookmarkGuardController", () => {
  let application

  const setupDom = ({ guest = true } = {}) => {
    document.body.innerHTML = `
      <div id="main-flashes"></div>
      <div id="bookmark-guard-root"
           data-controller="bookmark-guard"
           data-bookmark-guard-guest-value="${guest.toString()}"
           data-bookmark-guard-message-value="Please log in">
        <form class="bookmark-toggle">
          <label class="toggle-bookmark">
            <input class="toggle-bookmark" type="checkbox">
            Bookmark
          </label>
        </form>
      </div>
    `
  }

  const startController = () => {
    application = Application.start()
    application.register("bookmark-guard", BookmarkGuardController)
    return application
  }

  afterEach(() => {
    if (application) application.stop()
    application = null
    document.body.innerHTML = ""
  })

  it("shows a warning for guest bookmark clicks", async () => {
    setupDom({ guest: true })
    startController()
    await new Promise(resolve => setTimeout(resolve, 0))

    const input = document.querySelector("input.toggle-bookmark")
    const root = document.getElementById("bookmark-guard-root")
    const controller = application.getControllerForElementAndIdentifier(root, "bookmark-guard")
    controller.handleBookmarkClick({ target: input })

    const warning = document.querySelector(".guest-bookmark-warning")
    expect(warning).toBeTruthy()
    expect(warning.textContent).toMatch("Please log in")
    expect(warning.classList.contains("alert-warning")).toBeTruthy()
  })

  it("does not show a warning for logged-in users", async () => {
    setupDom({ guest: false })
    startController()
    await new Promise(resolve => setTimeout(resolve, 0))

    const input = document.querySelector("input.toggle-bookmark")
    const root = document.getElementById("bookmark-guard-root")
    const controller = application.getControllerForElementAndIdentifier(root, "bookmark-guard")
    controller.handleBookmarkClick({ target: input })

    const warning = document.querySelector(".guest-bookmark-warning")
    expect(warning).toBeNull()
  })

  it("replaces the existing warning on subsequent clicks", async () => {
    setupDom({ guest: true })
    startController()
    await new Promise(resolve => setTimeout(resolve, 0))

    const input = document.querySelector("input.toggle-bookmark")
    const root = document.getElementById("bookmark-guard-root")
    const controller = application.getControllerForElementAndIdentifier(root, "bookmark-guard")
    controller.handleBookmarkClick({ target: input })
    controller.handleBookmarkClick({ target: input })

    const warnings = document.querySelectorAll(".guest-bookmark-warning")
    expect(warnings.length).toBe(1)
  })
})
