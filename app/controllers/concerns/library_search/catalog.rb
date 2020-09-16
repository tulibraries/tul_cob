# frozen_string_literal: true

module LibrarySearch
  module Catalog
    extend ActiveSupport::Concern

    # Overrides the Blacklight Email Action so that we can send as a background job
    def email_action(documents)
      RecordEmailJob.perform_later(documents, { to: params[:to], message: params[:message] }, url_options)
    end
  end
end
