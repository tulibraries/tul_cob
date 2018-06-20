# frozen_string_literal: true

class ApplicationMailer < ActionMailer::Base
  default from: "books@temple.com"
  layout "mailer"
end
