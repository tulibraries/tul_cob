import { Controller } from "stimulus"

  function getMetaValue(name) {
      const element = document.head.querySelector(`meta[name="${name}"]`)
      return element.getAttribute("content")
    }

export default class extends Controller {
  static targets = [ "operator", "options" ]

  initialize() {
    $("option[value='begins_with']").hide();
  }

  select() {
    let count = $(event.currentTarget).data("count");
    let select_id = $(event.currentTarget).attr("id");
    let search_options = $(event.currentTarget).children("option:selected").text();
    let begins_with = document.getElementById(`operator[q_${count}]`);
    let begins_with_options = ["Title", "Author/creator/contributor", "Subject", "Publisher", "Call Number", "Series Title"]

    if(select_id.includes(count)) {
      if(begins_with_options.includes(search_options)) {
        $(begins_with).children("option[value='begins_with']").show();
      } else {
        $(begins_with).children("option[value='begins_with']").hide();
      }
    }
  }
}
