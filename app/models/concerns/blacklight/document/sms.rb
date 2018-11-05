# frozen_string_literal: true

# This module provides the body of an sms export based on availability and user
# selection.

module Blacklight::Document::Sms
  # Return a text string that will be the body of the email
  include ApplicationHelper

  def to_sms_text
    if self[:sms]
      [ :library, :location, :call_number ]
        .map { |field| self.dig(:sms, field) }
        .compact
        .join " "
    end
  end
end
