import $ from "./jquery"
import { onTurboLoad } from "./events"
import { whenBlacklightReady } from "./blacklight_helpers"

const overrideBlacklightModal = () => {
  whenBlacklightReady((Blacklight) => {
    if (!Blacklight.modal || !$) {
      return
    }

    Blacklight.modal.onFailure = (data) => {
      let message = "Network Error"
      if (Object.prototype.hasOwnProperty.call(data, "responseText")) {
        message = data.responseText
      }
      const contents = '<div class="modal-header">'
        + `<div class="modal-title">${message}</div>`
        + '<button type="button" class="blacklight-modal-close close" data-dismiss="modal" aria-label="Close">'
        + '  <span aria-hidden="true">&times;</span>'
        + "</button>"

      $(Blacklight.modal.modalSelector).find(".modal-content").html(contents)
      $(Blacklight.modal.modalSelector).modal("show")
    }
  })
}

onTurboLoad(overrideBlacklightModal)

export default overrideBlacklightModal
