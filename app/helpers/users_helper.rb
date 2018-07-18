# frozen_string_literal: true

module UsersHelper
  require "date"

  def make_date(date)
    DateTime.parse(date).strftime("%m/%d/%Y")
  end

  def loan_options(loan)
    options = { class: "form-check-input" }
    options[:disabled] = true unless loan.renewable?
    options
  end

  def new_user_with_redirect_path(redirect = request.url)
    new_user_session_path(redirect_to: redirect)
  end
end
