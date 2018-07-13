# frozen_string_literal: true

# This module provides the body of an email export based on the document's semantic values
module Blacklight::Document::Email
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
        body << I18n.t(label, value: value.join(" "))
      end
    end

    return body.join("\n") unless body.empty?
  end
end
