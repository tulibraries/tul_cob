# frozen_string_literal: true

require "active_support/core_ext/module/delegation"

# The default blacklight controller does not know how to handle multiple
# bookmark sources even though the model does.  These overrides fix that.
module MultiSourceBookmarks
  extend ActiveSupport::Concern

  included do
    # By default we wil be concerned with catalog and primo_central sources.
    # These sources correspond search engines for the source.
    blacklight_config.bookmark_sources = [ :catalog, :primo_central ]
  end

  # Overrides BookmarksController::index in order to run search on multiple apis.
  def index
    @bookmarks = token_or_current_or_guest_user.bookmarks
    @response = {}
    @document_list = []

    # This bit should probably be  made concurrent
    blacklight_config.bookmark_sources.each do |source|
      source_class = "#{source}_bookmark_search".classify.constantize
      ids = @bookmarks
        .select { |b| b.document_type == source_class.document_model.to_s }
        .collect { |b| b.document_id.to_s }

      _, docs = source_class.new(@search_state).fetch(ids)

      @document_list.append(*docs)
    end

    respond_to do |format|
      format.html {}
      format.rss { render layout: false }
      format.atom { render layout: false }
      format.json do
        render json: render_search_results_as_json
      end
    end
  end
end
