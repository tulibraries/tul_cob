import $ from "./jquery"

const loadArticleIframe = (selector) => {
  if (!$ || !selector) {
    return
  }

  const element = $(selector)
  const url = element.attr("data-iframe-url")

  if (element.attr("processed") === undefined) {
    element.attr("processed", true)
    $("<iframe>", {
      src: url,
      class: "bl_alma_iframe",
      id: `iframe-${selector}`,
    }).appendTo(selector)
  }
}

if (typeof window !== "undefined") {
  window.loadArticleIframe = loadArticleIframe
}

export default loadArticleIframe
