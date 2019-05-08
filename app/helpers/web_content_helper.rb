# frozen_string_literal: true

module WebContentHelper
  ## Overrides the Links to Show cause we want to go to the real thing
  def solr_web_content_document_path(document, options = {})
    document.fetch("url_display", "#")
  end

  def html_safe(options = {})
    options[:value].join("").html_safe
  end
end
