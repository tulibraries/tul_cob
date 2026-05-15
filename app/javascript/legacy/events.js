const supportsDOMEvents = () => typeof document !== "undefined"
  && typeof document.addEventListener === "function"

export const onTurboLoad = (callback) => {
  if (!supportsDOMEvents()) {
    return
  }

  const hasTurbo = typeof window !== "undefined" && window.Turbo

  if (hasTurbo) {
    document.addEventListener("turbo:load", callback)
  } else {
    if (document.readyState !== "loading") {
      callback()
    } else {
      document.addEventListener("DOMContentLoaded", callback, { once: true })
    }
  }
}

export const onWindowLoad = (callback) => {
  if (typeof window === "undefined" || typeof window.addEventListener !== "function") {
    return
  }

  window.addEventListener("load", callback)
}
