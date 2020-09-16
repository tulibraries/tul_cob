# frozen_string_literal: true

class RecordEmailJob < ApplicationJob
  queue_as :default

  def perform(documents, details, url_gen_params)
    RecordMailer.email_record(documents, details, url_gen_params).deliver
  end
end
