class UsersController < ApplicationController

  def loans
    @items = current_user.get_loans_list
  end

  def holds
    # [TODO] Uncomment out below and remove static @items array assignment when Alma::User#get_holds implemented
    #@items = current_user.get_holds_list
    @items = [
      {
        title: "History",
        due_date: "2014-06-23T14:00:00.000Z",
      }
    ]
  end

  def fines
    @items = current_user.get_fines_list
  end
end
