# frozen_string_literal: true

module WebContentHelper
  ## Overrides the Links to Show cause we want to go to the real thing
  def solr_web_content_document_path(document, options = {})
    # web_link_display is used for highlights
    document["web_url_display"] || document["web_base_url_display"] || document.fetch("web_link_display", "#")
  end

  def format_types(type)
    unless type == "People/Staff Directory"
      type = type.pluralize(2)
    end
    type.titlecase
  end

  def capitalize_type(document)
    type = document[:value].first
    type.titlecase
  end

  def format_phone_number(document)
    phone_number = document[:value].first
    number_to_phone(phone_number)
  end

  def website_list(document)
    field_content =  document[:value].first.gsub(/\[|\]/) { |match| }.split(",")
    field_content.map { |list_item| content_tag(:li,  list_item, class: "list_items") }.join("").html_safe
  end

end
