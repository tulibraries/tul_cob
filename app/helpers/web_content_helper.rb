# frozen_string_literal: true

module WebContentHelper
  ## Overrides the Links to Show cause we want to go to the real thing
  def solr_web_content_document_path(document, options = {})
    # web_link_display is used for highlights
    document["web_base_url_display"] || document.fetch("web_link_display", "#")
  end

  def capitalize_types(type)
    type.titlecase
  end
end
