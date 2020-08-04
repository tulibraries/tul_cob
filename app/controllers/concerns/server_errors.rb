# frozen_string_literal: true

module ServerErrors
  extend ActiveSupport::Concern

  included do
    # We handle all unknown and unplanned exceptions here
    # If an exception arises that could benefit from more
    # detailed notification to end user or Honeybadger
    # consider writing a custom handler below.
    rescue_from Exception do |exception|
      message = "#{exception.message} \n #{exception.backtrace[0]}"
      Honeybadger.notify(message)
      render "errors/internal_server_error", status: :internal_server_error
    end

    rescue_from BlacklightRangeLimit::InvalidRange do
      redirect_back(fallback_location: root_path, notice: "The start year must be before the end year.")
    end

    rescue_from Blacklight::Exceptions::RecordNotFound,
                with: :invalid_document_id_error

    rescue_from Blacklight::Exceptions::InvalidRequest do |exception|
      Honeybadger.notify(exception.message)
      render "errors/unsupported_query", status: :bad_request
    end

    rescue_from Primo::Search::SearchError do |exception|
      message = exception.message
      Honeybadger.notify(message)
      render "errors/internal_server_error", status: :bad_gateway
    end
  end
end
