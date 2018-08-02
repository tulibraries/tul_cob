# frozen_string_literal: true

module UsersHelper
  require "date"

  def expiry_date(hold)
    make_date(hold.expiry_date) rescue "N/A"
  end

  def make_date(date)
    DateTime.parse(date).strftime("%m/%d/%Y")
  end

  def loan_options(loan)
    options = { class: "form-check-input" }
    options[:disabled] = true unless loan.renewable?
    options
  end
end
