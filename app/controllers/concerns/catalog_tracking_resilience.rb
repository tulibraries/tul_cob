# frozen_string_literal: true

module CatalogTrackingResilience
  extend ActiveSupport::Concern

  included do
    before_action :clear_stale_search_context, only: :show
  end

  def track
    tracking_params = params.permit(:counter, :search_id, :per_page, :document_id, :redirect, :id)
    search_session["counter"] = tracking_params[:counter]
    search_session["id"] = tracking_params[:search_id]
    search_session["per_page"] = tracking_params[:per_page]
    search_session["document_id"] = tracking_params[:document_id]

    if tracking_params[:redirect].present? &&
        (tracking_params[:redirect].starts_with?("/") || tracking_params[:redirect] =~ URI::DEFAULT_PARSER.make_regexp)
      uri = URI.parse(tracking_params[:redirect])
      path = uri.query ? "#{uri.path}?#{uri.query}" : uri.path
      redirect_to path, status: :see_other
    else
      redirect_to({ action: :show, id: tracking_params[:id] }, status: :see_other)
    end
  end

  private

    def clear_stale_search_context
      session_id = search_session["id"] || search_session[:id]
      return if session_id.blank?
      return if current_search_session.present?

      %i[id counter per_page document_id total].each do |key|
        search_session.delete(key.to_s)
        search_session.delete(key)
      end
    end
end
