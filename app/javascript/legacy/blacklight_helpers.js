const whenBlacklightReady = (callback, attempt = 0) => {
  if (typeof window === "undefined") {
    return
  }

  const { Blacklight } = window
  if (Blacklight) {
    callback(Blacklight)
    return
  }

  if (attempt > 200) {
    return
  }

  setTimeout(() => whenBlacklightReady(callback, attempt + 1), 50)
}

const onBlacklightLoad = (handler) => {
  whenBlacklightReady((Blacklight) => {
    if (typeof Blacklight.onLoad === "function") {
      Blacklight.onLoad(handler)
    }
  })
}

export { whenBlacklightReady, onBlacklightLoad }
