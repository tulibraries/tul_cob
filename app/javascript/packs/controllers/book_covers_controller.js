import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    var queries = [];
    $(".thumbnail").each(function(index, thumbnail) {
      let isbn = $(thumbnail).attr('data-isbn');
      let lccn = $(thumbnail).attr('data-lccn');
      let oclc = $(thumbnail).attr('data-oclc');

      if(isbn) {
        isbn.split(",").map(function(value){
          queries.push("ISBN:" + value);
        })
      } else if(lccn) {
        lccn.split(",").map(function(value){
          queries.push("LCCN:" + value);
        })
      } else if(oclc) {
        oclc.split(",").map(function(value){
          queries.push("OCLC:" + value);
        })
      } else {
        $("#book-cover-image").remove();
      }
    });

    $.ajax(
      {
        url: "https://books.google.com/books?jscmd=viewapi&bibkeys=" + queries.join(),
        dataType: "jsonp",
        jsonp: "callback"
      }
    ).done(
      function(response) {
        for (var bib in response) {
          let b = response[bib];
          if(b.hasOwnProperty("thumbnail_url")) {
            let type = b.bib_key.split(":")[0];
            let identifier = b.bib_key.split(":")[1];
            $('[data-' + type.toLowerCase() + '*=' + identifier + '] .book_cover').attr("src" , b.thumbnail_url).removeClass("invisible").addClass("google-image");
            $('[data-' + type.toLowerCase() + '*=' + identifier + '] .default').remove();
          }
        }

        for (var bib in response) {
          let b = response[bib];
          if(b.hasOwnProperty("preview_url")) {
            let type = b.bib_key.split(":")[0];
            let identifier = b.bib_key.split(":")[1];
            $('[data-' + type.toLowerCase() + '*=' + identifier + '] .preview').attr("href", b.preview_url).attr("target", "_blank").removeClass("invisible").addClass("google-preview");
            break;
          }
        }
      }
    )
  }

}