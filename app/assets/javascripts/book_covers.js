$(document).on('turbolinks:load', function() {
  $.ajax(
    {
      url: "https://books.google.com/books?jscmd=viewapi&bibkeys=ISBN:9781935410812,LCCN:2015048918",
      dataType: "jsonp",
      jsonp: "callback"
    }
  ).done(
    function(response) {
      for (var bib in response) {
        b = response[bib];
        if(b.hasOwnProperty("thumbnail_url")) {
          type, identifier = b.bib_key.split(":")[1];
          $('[data-' + type + '=' + identifier + ']').html(thumbnail_img )
        }
      }
    }
  )
 }
)

function thumbnail_img(gb_result) {
  "<img src='" + gb_result.thumbnail_url +  "' />"
}
