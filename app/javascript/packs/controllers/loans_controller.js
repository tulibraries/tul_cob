import { Controller } from "@hotwired/stimulus"

  function getMetaValue(name) {
    const element = document.head.querySelector(`meta[name="${name}"]`)
    return element.getAttribute("content")
  }

export default class extends Controller {
  static targets = [ "table", "spinner"]


  initialize() {
    this.get_loans()
  }

  get_loans() {
    fetch(this.data.get("url"), {
      credentials: "same-origin",
      headers: {
        "X-CSRF-Token": getMetaValue("csrf-token")
      },
    })
      .then(response => response.text())
      .then(html => {
        $(this.spinnerTarget).remove();
        this.tableTarget.innerHTML = html
      })
  }

  connect() {
    $('input[type=checkbox]').click(function(){
      var x = document.getElementsByName("loan_ids[]");
      var checked = false;
      $(x).each(function() {
        if( $(this).prop('checked')){
          checked = true;
        }
      });
    });
  }

  selectallchecks() {
    var x = document.getElementsByName("loan_ids[]");
    var y = document.getElementById("checkall");
    var i;
    if (y.checked == true) {
      for (i = 0; i < x.length; i++) {
        if (x[i].type == "checkbox") {
          x[i].checked = true;
        }
      }
    }
    else {
      for (i = 0; i < x.length; i++) {
        if (x[i].type == "checkbox") {
          x[i].checked = false;
        }
      }
    }
  }

  deselectallchecks() {
    var x = document.getElementsByName("loan_ids[]");
    var y = document.getElementById("checkall");
    y.checked = false;
    var i;
    for (i = 0; i < x.length; i++) {
      if (x[i].type == "checkbox") {
          x[i].checked = false;
      }
    }
  }

}
