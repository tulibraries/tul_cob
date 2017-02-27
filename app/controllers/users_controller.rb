class UsersController < ApplicationController

  def account
    @loans = current_user.get_loans
    @holds = current_user.get_holds
    @fines = current_user.get_fines
  end


  def loans
    @items = current_user.get_loans
  end

  def holds
    @items = current_user.get_holds
  end

  def fines
    @items = current_user.get_fines
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
