import $ from "./jquery"
import BlacklightAlma from "./blacklight_alma"
import { onTurboLoad } from "./events"
import { onBlacklightLoad } from "./blacklight_helpers"

const registerLongListPlugin = () => {
  if (!$ || $.fn.longList) {
    return
  }

  $.fn.longList = function longList() {
    return this.each(function initList() {
      const list = $(this)
      const children = list.children().filter(() => true)
      const type = list.data("list-type")
      const moreButton = $(`<button class="btn bg-white text-cherry-red border border-light-grey m-0 show-all">Show All<span class="sr-only"> at ${type}</span></button>`)
      const lessButton = $(`<button class="btn bg-white text-cherry-red border border-light-grey m-0 show-less">Show Less<span class="sr-only"> at ${type}</span></button>`)

      const init = () => {
        if (children.length > 5) {
          children.hide().slice(0, 5).show()
          moreButton.on("click", (event) => {
            event.preventDefault()
            children.hide().slice(0, 10000).show()
            moreButton.hide()
            lessButton.fadeIn()
          })
          lessButton.on("click", (event) => {
            event.preventDefault()
            children.hide().slice(0, 5).show()
            lessButton.hide()
            moreButton.fadeIn()
          })
          list.append(moreButton)
          lessButton.insertAfter(moreButton).hide()
        }
      }

      init()
    })
  }
}

const initializeAvailabilityLoader = () => {
  if (typeof document === "undefined") {
    return
  }

  if (!document.querySelector(".availability-ajax-load")) {
    return
  }

  const alma = new BlacklightAlma()
  alma.loadAvailability()
}

const registerLongListOnLoad = () => {
  if (!$) {
    return
  }

  onBlacklightLoad(() => {
    $("[data-long-list]").longList()
  })
}

registerLongListPlugin()
registerLongListOnLoad()
onTurboLoad(() => {
  initializeAvailabilityLoader()
})

export { initializeAvailabilityLoader }
