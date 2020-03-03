import { Controller } from "stimulus"

  function getMetaValue(name) {
      const element = document.head.querySelector(`meta[name="${name}"]`)
      return element.getAttribute("content")
    }

export default class extends Controller {
  static targets = [ "operator" ]

  connect() {
    $("option[value='begins_with']").hide();
  }

  select() {
    let search_options_1 = $("#f_1 option:selected").text();
    let search_options_2 = $("#f_2 option:selected").text();
    let search_options_3 = $("#f_3 option:selected").text();

    let begins_with_options = ["Title", "Author/creator/contributor", "Subject", "Publisher", "Call Number", "Series Title"]

    if(begins_with_options.includes(search_options_1)) {
      console.log("HI")
      $("option[value='begins_with']").show();
      $("option[value='begins_with']").text("begins with");
    } else {
      $("option[value='begins_with']").hide();
    }
  }
}
