class UsersController < ApplicationController

  def loans
    @items = current_user.get_loans_list
  end

  def holds
    @items = current_user.get_holds_list

  end

  def fines
    @items = current_user.get_fines_list
  end
end
