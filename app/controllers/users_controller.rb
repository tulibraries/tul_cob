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
    binding.pry

    # Pass loan_id and loan status to view
    @loan_id =  params[:loan_id]
    result = lib_user.renew_loan(@loan_id)
    @message = result.renewed? ? "RENEWED" : result.error_message

    respond_to do |format|
      format.js
    end
  end

  def renew_selected
    logger.debug "Renew Selected Loans"

    binding.pry
    @items = params[:selected_loan_ids]
    lib_user = Alma::User.find({user_id: current_user.uid})

    #@renew_selected_results = lib_user.renew_multiple_loans(@items)

    respond_to do |format|
      format.js
    end
  end
  
  def renew_all
    binding.pry
    logger.debug "Renew All"

    lib_user = Alma::User.find({user_id: current_user.uid})

    @renew_all_results = lib_user.renew_all_loans

    respond_to do |format|
      format.js
    end
  end
  
  def results_message(result)
        #message = result.error_message unless result.renewed?
  end

  def multi_results_messages(results)
    results.map { |r|
      logger.debug "Multi Renewed: #{r.has_error? ? r.error_message : r.message}"
      [r.has_error? ? r.error_message : r.message]
    }
  end
end
