# frozen_string_literal: true

# This module provides the body of an sms export based on availability and user
# selection.

module LibrarySearch::Document::Sms
  # Return a text string that will be the body of the email
  include ApplicationHelper
  include Blacklight::Document::Sms

  def to_sms_text(config = nil)
    if self[:sms]
      [ :library, :location, :call_number ]
        .map { |field|
          if field == :location
            materials_location(self[:sms])
          else
            self.dig(:sms, field)
          end
        }
        .compact
        .join " "
    end
  end
end
