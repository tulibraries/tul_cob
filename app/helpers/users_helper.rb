module UsersHelper
	require 'date'

	def make_date date
		DateTime.parse(date).strftime("%m/%d/%Y") 
	end
	def total_holds holds
		holds.list.size
	end
	def total_loans loans
		loans.list.size
	end
	def is_overdue status
		status == 'Overdue' ? status : ''
	end
end
