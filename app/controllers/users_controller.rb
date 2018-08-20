# frozen_string_literal: true

class UsersController < ApplicationController
  before_action :require_admin!, only: [:index]
  before_action :require_non_production!, only: [:index]


  def require_admin!
    redirect_to root_path unless current_user && current_user.admin
  end

  def require_non_production!
    redirect_to root_path if Rails.env.production? && ENV["ALLOW_IMPERSONATOR"].downcase != "yes"
  end

  def index
    registered_users = User.where.not(guest: true)
    @users = registered_users.order(:id)
  end

  def impersonate
    user = User.find(params[:id])
    impersonate_user(user)
    redirect_to root_path
  end

  def stop_impersonating
    stop_impersonating_user
    redirect_to root_path
  end

  def account
    no_cache
    @user = current_user
    if @user.uid.nil?
      flash[:error] = "It may take a few days for your library account to be created. If you have questions about this please call 215-204-0744."
      redirect_to root_path
    end
  end

  def holds
    holds = current_user.holds
    if holds.success?
      render partial: "users/holds_details", layout: nil, locals: { holds: holds }
    else
      render "Problem!"
    end
  end

  def fines
    fines = current_user.fines
    if fines.success?
      render partial: "users/fines_details", layout: nil, locals: { fines: fines }
    else
      render "Problem!"
    end
  end


  def loans
    loans = current_user.loans
    if loans.success?
      render partial: "users/loans_details", layout: nil, locals: { loans: loans }
    else
      render "Problem!"
    end
  end

  def renew
    lib_user = Alma::User.find(user_id: current_user.uid)

    # Pass loan_id and loan status to view
    @loan_id = params[:loan_id]
    result = lib_user.renew_loan(@loan_id)
    @message = result.renewed? ? "RENEWED" : result.error_message

    respond_to do |format|
      format.js
    end
  end

  def renew_selected
    if params[:loan_ids].nil?
      redirect_to(users_account_path) && return
    else
      renew_results = current_user.renew_selected(params[:loan_ids])
      @renew_responses = multiple_renew_responses(renew_results, params[:loan_ids])
      logger.info "RENEWAL STATUS:"
      logger.info ap(@renew_responses)

      #    respond_to do |format|
      #      format.js
      #    end
    end
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
    renew_results.map.with_index do |r, i|
      logger.debug "Multi Renewed: #{r.has_error? ? r.error_message : r.message}"
      renew_response(r, loan_id_list[i])
    end
  end
end
