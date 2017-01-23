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

  def renew
    respond_to do |format|
      lib_user = Alma::User.find({user_id: current_user.alma_id})
      result = lib_user.renew_loan({loan_id: params[:loan_id]})
      format.js
    end
  end
end
