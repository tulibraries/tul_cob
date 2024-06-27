# frozen_string_literal: true

# This module provides the body of an email export based on the document's semantic values
module LibrarySearch::Document::Email
  include Blacklight::Document::Email
  include ApplicationHelper

  # Return a text string that will be the body of the email
  # Overridden in order to add our own custom fields to email text.
  def to_email_text(config = nil)
    semantics = to_semantic_values
    body = []
    ["title", "imprint", "author", "contributor",
    "isbn", "issn", "production", "distribution", "manufacture"].each do |field|
      if !semantics[field.to_sym].blank?
        if field == "contributor"
          contributor = semantics[:contributor].map { |c|
            JSON.parse(c)
          }
          value = contributor.map { |c| c["name"] }
          label = "blacklight.email.text.#{field}"
          body << I18n.t(label, value: value.join("; ").gsub("|", "; "))
        else
          value = semantics[field.to_sym]
          label = "blacklight.email.text.#{field}"
          body << I18n.t(label, value: value.join("; ").gsub("|", "; "))
        end
      end
    end
    body << add_holdings_information
    return body.join("\n") unless body.empty?
  end

  def add_holdings_information
    holdings = document_items_grouped.collect { |library, locations| locations.collect { |location, items| items.collect { |item| library + " - " + location + " - " + item["call_number_display"] }.uniq } }
    return I18n.t("blacklight.email.text.location", value: "\n" + holdings.join("\n")) unless holdings.empty?
  end
end
