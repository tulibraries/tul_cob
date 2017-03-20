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

  def renew_selected
    if params[:loan_ids].nil?  
      redirect_to '/users/account/' and return
    else
      lib_user = Alma::User.find({user_id: current_user.uid})

      renew_results = lib_user.renew_multiple_loans(params[:loan_ids])
      @renew_responses = multiple_renew_responses(renew_results, params[:loan_ids])
      logger.info "RENEWAL STATUS:"
      logger.info ap(@renew_responses)

  #    respond_to do |format|
  #      format.js
  #    end
    end
  end
  
  def renew_all
    logger.debug "Renew All"

    lib_user = Alma::User.find({user_id: current_user.uid})

    @renew_all_results = lib_user.renew_all_loans

#    respond_to do |format|
#      format.js
#    end
  end
  
  def renew_response(result, loan_id)
    {
      loan_id:  loan_id,
      renewed:  result.renewed?,
      title:    result.item_title,
      due_date: result.due_date,
      message:  result.has_error? ? result.error_message : result.message
    }
  end

  def multiple_renew_responses(renew_results, loan_id_list)
    renew_results.map.with_index { |r, i|
      logger.debug "Multi Renewed: #{r.has_error? ? r.error_message : r.message}"
      renew_response(r, loan_id_list[i])
    }
  end
end
