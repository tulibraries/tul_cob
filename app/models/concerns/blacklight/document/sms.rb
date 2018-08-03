# frozen_string_literal: true

# This module provides the body of an email export based on the document's semantic values

module Blacklight::Document::Sms
  # Return a text string that will be the body of the email
  include ApplicationHelper

  def to_sms_text
    semantics = self.to_semantic_values
    body = []

    locations = semantics[:location].map { |l| render_location(l) }.join(", ")
    body << I18n.t("blacklight.sms.text.location", value: locations) unless locations.empty?

    return body.join unless body.empty?
  end
end
