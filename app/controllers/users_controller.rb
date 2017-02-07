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
    lib_user = Alma::User.find({user_id: current_user.uid})

    # Pass loan_id and loan status to view
    @loan_id =  params[:loan_id]
    result = lib_user.renew_loan(@loan_id)
    @message = result.renewed? ? "RENEWED" : result.error_message

    respond_to do |format|
      format.js
    end
  end

  def results_message(result)
        #message = result.error_message unless result.renewed?
  end
end
