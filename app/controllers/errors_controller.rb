# frozen_string_literal: true

class ErrorsController < ApplicationController
  def not_found
    render(layout(status: 404, formats: :html))
  end

  def internal_server_error
    render(layout(status: 500, formats: :html))
  end

  private
    def layout(options)
      request.env["REQUEST_PATH"]&.match?(/^\/almaws/) ? options.merge(layout: false) : options
    end
end
