$(document).on('turbolinks:load', function() {
  var queries = [];
  $(".thumbnail").each(function(index, thumbnail) {
    lccn = $(thumbnail).attr('data-lccn');
    isbn = $(thumbnail).attr('data-isbn');
    if(lccn) {
      queries.push("LCCN:" + lccn);
    }
    else if(isbn) {
      queries.push("ISBN:" + isbn);
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
          $('[data-' + type.toLowerCase() + '=' + identifier + '] .book_cover').attr("src" , b.thumbnail_url).removeClass("invisible").addClass("google-image");
          $('[data-' + type.toLowerCase() + '=' + identifier + '] .default').remove();
        }
      }
    }
  )
})
