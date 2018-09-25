# frozen_string_literal: true

# This module provides the body of an email export based on the document's semantic values
module Blacklight::Document::Email
  include ApplicationHelper
  # Return a text string that will be the body of the email
  # Overridden in order to add our own custom fields to email text.
  def to_email_text
    semantics = to_semantic_values
    body = []
    [ "title", "imprint", "author",
      "contributor", "isbn", "issn", "alma_mms" ].each do |field|
      if !semantics[field.to_sym].blank?
        value = semantics[field.to_sym]
        label = "blacklight.email.text.#{field}"
        body << I18n.t(label, value: value.join("; ").gsub("|", "; "))
      end
    end
    body << add_holdings_information
    return body.join("\n") unless body.empty?
  end

  def add_holdings_information
    holdings = materials.collect { |material| material["library"] + " - " + material["location"] + " - " + material["call_number"] }
    return I18n.t("blacklight.email.text.location", value: "\n" + holdings.join("\n"))
  end
end
