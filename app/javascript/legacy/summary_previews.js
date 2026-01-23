import $ from "./jquery"
import { onTurboLoad } from "./events"

const SUMMARY_LIMIT = 300

const collapsedStyles = {
  display: "-webkit-box",
  "-webkit-box-orient": "vertical",
  "-webkit-line-clamp": "2",
  "margin-bottom": "0",
}

const applyCollapsedStyles = (element) => {
  Object.entries(collapsedStyles).forEach(([key, value]) => {
    element.css(key, value)
  })
}

const initializeSummaryPreviews = () => {
  if (!$) {
    return
  }

  const previews = document.getElementsByClassName("summary-previews")

  $(previews).each(function initPreview() {
    const readLess = $('<a class="read-less">less</a>')
    const readMore = $('<a class="read-more">read more</a>')

    if ($(this).text().length > SUMMARY_LIMIT) {
      applyCollapsedStyles($(this))
      $(readMore).insertAfter($(this))
      $(readLess).insertAfter($(this)).hide()
    }

    $(readMore).on("click", function handleReadMoreClick() {
      $(this).hide()
      $(this).siblings("div.summary-previews").removeAttr("style")
      $(readLess).show()
    })

    $(readLess).on("click", function handleReadLessClick() {
      $(this).hide()
      $(readMore).removeAttr("style")
      applyCollapsedStyles($(this).prev("div"))
    })
  })
}

onTurboLoad(initializeSummaryPreviews)

export default initializeSummaryPreviews
