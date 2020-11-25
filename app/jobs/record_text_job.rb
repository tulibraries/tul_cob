# frozen_string_literal: true

class RecordTextJob < ApplicationJob
  queue_as :default

  def perform(documents, to, url_options)
    RecordMailer.sms_record(documents, to, url_options).deliver
  end
end
