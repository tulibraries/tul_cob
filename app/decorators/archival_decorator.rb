# frozen_string_literal: true

class ArchivalDecorator < BentoSearch::StandardDecorator
  def display_date
    if custom_data && custom_data["archival_dates"].present?
      return "<span class='bento-label'>Dates: </span>".html_safe + custom_data["archival_dates"]
    end
    super
  end

  def raw_json
    @raw_json ||= JSON.parse(_base.custom_data["json"])
  end

  def collections
    collection_ref = _base.custom_data["collection_ref"]
    return nil unless collection_ref

    collection_title = _base.custom_data["collection_title"]
    collection_url = "https://scrcarchivesspace.temple.edu#{collection_ref}"

    return "<span class='bento-label'>In collection: </span><a href='#{collection_url}' target='_blank' rel='noopener noreferrer'>#{collection_title}</a>".html_safe unless custom_data["primary_types"] == "resource"
  end

  def primary_types
    type  = custom_data["primary_types"].to_s.chomp(".")
    label = custom_data["primary_type_labels"].to_s.chomp(".")
    level = custom_data["level"]&.titlecase.to_s.chomp(".")

    return nil if type.blank?

    text = (type == "resource" ? level : label).to_s.strip
    "#{primary_type_icon(type)} #{text}".html_safe
  end

  def primary_type_icon(type)
    case type
    when "resource"
      "<span class='resource'></span>".html_safe
    when "archival_object"
      "<span class='archival_object'></span>".html_safe
    when "agent_person"
      "<span class='agent_person'></span>".html_safe
    when "agent_family"
      "<span class='agent_family'></span>".html_safe
    when "agent_corporate_entity"
      "<span class='agent_corporate_entity'></span>".html_safe
    when "classification"
      "<span class='classification'></span>".html_safe
    else
      "".html_safe
    end
  end
end
