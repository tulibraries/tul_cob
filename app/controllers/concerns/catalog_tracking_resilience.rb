# frozen_string_literal: true

module CatalogTrackingResilience
  extend ActiveSupport::Concern

  included do
    before_action :clear_stale_search_context, only: :show
  end

  def track
    search_session["counter"] = params[:counter]
    search_session["id"] = params[:search_id]
    search_session["per_page"] = params[:per_page]
    search_session["document_id"] = params[:document_id]

    if params[:redirect].present? && (params[:redirect].starts_with?("/") || params[:redirect] =~ URI::DEFAULT_PARSER.make_regexp)
      uri = URI.parse(params[:redirect])
      path = uri.query ? "#{uri.path}?#{uri.query}" : uri.path
      redirect_to path, status: :see_other
    else
      redirect_to({ action: :show, id: params[:id] }, status: :see_other)
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
