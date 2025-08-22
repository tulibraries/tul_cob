# frozen_string_literal: true

class DocumentDecorator < SimpleDelegator
  include Rails.application.routes.url_helpers

  # General utility methods moved from CatalogHelper
  def library_link_url
    Rails.configuration.library_link
  end

  def formatted_id
    "doc-#{id}"
  end

  # Instance method that needs request URL passed to it
  def redirect_url(request_url)
    Rails.application.routes.url_helpers.new_user_session_path(
      redirect_to: "#{request_url}##{formatted_id}"
    )
  end

  # Static methods that match the original CatalogHelper interface
  def self.doc_id(id)
    "doc-#{id}"
  end

  def self.doc_redirect_url(id, request_url)
    Rails.application.routes.url_helpers.new_user_session_path(
      redirect_to: "#{request_url}#doc-#{id}"
    )
  end

  private

    def new_user_session_path(options = {})
      Rails.application.routes.url_helpers.new_user_session_path(options)
    end
end
