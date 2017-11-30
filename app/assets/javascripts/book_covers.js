$(document).on('turbolinks:load', function() {
  thumbnail_list = $(".thumbnail");
  thumbnail_list.each(function(index, thumbnail) {
    console.log (index, thumbnail);
    lccn = $(thumbnail).attr('data-lccn');
    isbn = $(thumbnail).attr('data-isbn');
    console.log (index, lccn);
    console.log (index, isbn);
    //thumbnail_url = "https://books.google.com/books?jscmd=viewapi&bibkeys=ISBN:9781935410812,LCCN:2015048918";
    thumbnail_url = "https://books.google.com/books?jscmd=viewapi&bibkeys=ISBN:" + isbn + ",LCCN:" + String(lccn);
    console.log(index, "Thumbnail_url", thumbnail_url);
    
    $.ajax(
      {
        url: thumbnail_url,
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
              $('[data-' + type.toLowerCase() + '=' + identifier + ']').html(thumbnail_img(b) );
            }
          }
        }
      )
   }
  )
 }
)

function thumbnail_img(gb_result) {
  return "<img src='" + gb_result.thumbnail_url +  "' />"
}
