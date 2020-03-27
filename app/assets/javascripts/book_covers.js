$(document).on('turbolinks:load', function() {
  var queries = [];
  $(".thumbnail").each(function(index, thumbnail) {
    isbn = $(thumbnail).attr('data-isbn');
    lccn = $(thumbnail).attr('data-lccn');
    oclc = $(thumbnail).attr('data-oclc');

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
        queries.push("ISBN:" + value);
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
        b = response[bib];
        if(b.hasOwnProperty("thumbnail_url")) {
          type = b.bib_key.split(":")[0];
          identifier = b.bib_key.split(":")[1];
          $('[data-' + type.toLowerCase() + '*=' + identifier + '] .book_cover').attr("src" , b.thumbnail_url).removeClass("invisible").addClass("google-image");
          $('[data-' + type.toLowerCase() + '*=' + identifier + '] .default').remove();
        }
        if(b.hasOwnProperty("preview_url")) {
          type = b.bib_key.split(":")[0];
          identifier = b.bib_key.split(":")[1];
          $('[data-' + type.toLowerCase() + '*=' + identifier + '] .preview').attr("href", b.preview_url).removeClass("invisible").addClass("google-preview");
        }
      }
    }
  )
})
