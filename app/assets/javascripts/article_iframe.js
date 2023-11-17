function loadArticleIframe(id) {
    var element = $(id)
    var url = element.attr("data-iframe-url")
  
    if (element.attr("processed") == undefined) {
      element.attr("processed", true);
      $("<iframe>", {
        src: url,
        "class": "bl_alma_iframe",
        id: 'iframe-' + id,
      }).appendTo(id);
    }
  }