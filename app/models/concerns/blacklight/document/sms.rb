# frozen_string_literal: true

# This module provides the body of an sms export based on availability and user
# selection.

module Blacklight::Document::Sms
  # Return a text string that will be the body of the email
  include ApplicationHelper

  def to_sms_text
    body = []

    # self[:sms] gets set by CatalogController.sms_action
    if self[:sms]
      body << self[:sms][:call_number]
      body << "#{self[:sms][:library]} (#{self[:sms][:location]})"
      body << self[:sms][:title]
    end

    return body.join("\n") unless body.empty?
  end
end
