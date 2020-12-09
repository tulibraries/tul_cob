# frozen_string_literal: true

class ErrorsController < ApplicationController
  def not_found
    respond_to do |format|
      format.woff2 { render plain: "", status: 400, content_type: "text/plain" }
      format.css { render plain: "", status: 400, content_type: "text/plain" }
      format.js { render plain: "", status: 400, content_type: "text/plain" }
      format.all { render(layout(status: 404, formats: :html)) }
    end
  end

  def internal_server_error
    render(layout(status: 500, formats: :html))
  end

  private
    def layout(options)
      request.env["REQUEST_PATH"]&.match?(/^\/almaws/) ? options.merge(layout: false) : options
    end
end
