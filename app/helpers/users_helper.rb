# frozen_string_literal: true

module UsersHelper
  require 'date'

  def make_date(date)
    DateTime.parse(date).strftime('%m/%d/%Y')
  end

  def total_holds(holds)
    holds.list.size
  end

  def total_loans(loans)
    loans.list.size
  end

  def is_overdue(status)
    status == 'Overdue' ? status : ''
  end

  def is_not_renewable?(loan)
    # Alma API returns string true or false.
    # If renewable attribute exists and has value of 'false', return true,
    # If renewable attribute doesn't exist or has value 'true' return false
    loan&.renewable.eql? 'false'
  end

  def loan_options(loan)
    options = { class: 'form-check-input' }
    options[:disabled] = true if is_not_renewable?(loan)
    options
  end
end
