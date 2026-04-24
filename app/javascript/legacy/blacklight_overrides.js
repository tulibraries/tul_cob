window.Blacklight.modal.onFailure = function (data) {
  let message = "Network Error";
  if(data.hasOwnProperty("responseText")) {
    message = data.responseText;
  }
  var contents = '<div class="modal-header">' + '<div class="modal-title">' + message + '</div>' + '<button type="button" class="blacklight-modal-close close" data-dismiss="modal" aria-label="Close">' + '  <span aria-hidden="true">&times;</span>' + '</button>';
  $(window.Blacklight.modal.modalSelector).find('.modal-content').html(contents);
  $(window.Blacklight.modal.modalSelector).modal('show');
};
