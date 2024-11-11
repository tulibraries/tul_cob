import Modal from '../blacklight/modal'

Modal.onFailure = function (data) {
  message = "Network Error";
  if(data.hasOwnProperty("responseText")) {
    message = data.responseText;
  }
  var contents = '<div class="modal-header">' + '<div class="modal-title">' + message + '</div>' + '<button type="button" class="blacklight-modal-close close" data-dismiss="modal" aria-label="Close">' + '  <span aria-hidden="true">&times;</span>' + '</button>';
  $(Modal.modalSelector).find('.modal-content').html(contents);
  $(Modal.modalSelector).modal('show');
};
