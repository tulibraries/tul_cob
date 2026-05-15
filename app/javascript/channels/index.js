import consumer from "channels/consumer"

if (typeof window !== "undefined") {
  window.App = window.App || {}
  window.App.cable = consumer
}

export { consumer }
