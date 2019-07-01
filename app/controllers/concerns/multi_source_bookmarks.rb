# frozen_string_literal: true

require "active_support/core_ext/module/delegation"

# The default blacklight controller does not know how to handle multiple
# bookmark sources even though the model does.  These overrides fix that.
module MultiSourceBookmarks
  extend ActiveSupport::Concern

  included do
    # By default we will be concerned with catalog and primo_central sources.
    # These sources correspond search engines for the source.
    blacklight_config.bookmark_sources = [ :catalog, :primo_central ]
  end

  # Overrides BookmarksController::action_documents in order to get documents from multiple apis.
  def action_documents
    search_service.fetch([])
    @bookmarks = token_or_current_or_guest_user.bookmarks
    document_list = []
    # This bit should probably be  made concurrent
    blacklight_config.bookmark_sources.each do |source|
      source_class = "#{source}_bookmark_search".classify.constantize
      ids = @bookmarks
        .select { |b| source_class.handle_bookmark_search?(b.document_type) }
        .collect { |b| b.document_id.to_s }

      if !ids.empty?
        search_service = source_class.new(@search_state).search_service
        @response, docs = search_service.fetch(ids)
        document_list.append(*docs)
      end
    end

    # Reorder the document list to match the bookmark order.
    document_map = document_list
      .map { |d| [d.id, d] }.to_h

    # Replacing ^TN_ in ids to add backward compatibility.
    @documents = @bookmarks
      .map { |b| document_map[b.document_id.gsub(/^TN_/, "")] }
      .compact

    # Capture full document list in response for correct current_bookmarks count.
    @response.instance_variable_set(:@documents, @documents) if @response

    # Just display all the bookmarks in one page
    #
    @response["rows"] = @bookmarks.count if @response
    [@response, @documents]
  end

  # Overrides BookmarksController::index in order to run search on multiple apis.
  def index
    action_documents
    no_cache

    respond_to do |format|
      format.html {}
      format.ris
      format.rss { render layout: false }
      format.atom { render layout: false }
      format.json do
        render json: render_search_results_as_json
      end
    end
  end

  # Overrides delete method in order to pass bookmarks via param.
  def destroy
    @bookmarks =
      if params[:bookmarks]
        permit_bookmarks[:bookmarks]
      else
        [{ document_id: params[:id], document_type: blacklight_config.document_model.to_s }]
      end

    success = @bookmarks.all? do |bookmark|
      bookmark = current_or_guest_user.bookmarks.find_by(bookmark)
      bookmark && bookmark.delete && bookmark.destroyed?
    end

    if success
      if request.xhr?
        render(json: { bookmarks: { count: current_or_guest_user.bookmarks.count } })
      elsif respond_to? :redirect_back
        redirect_back fallback_location: bookmarks_path, notice: I18n.t("blacklight.bookmarks.remove.success")
      else
        # Deprecated in Rails 5.0
        redirect_to :back, notice: I18n.t("blacklight.bookmarks.remove.success")
      end
    elsif request.xhr?
      head 500 # ajaxy request needs no redirect and should not have flash set
    elsif respond_to? :redirect_back
      redirect_back fallback_location: bookmarks_path, flash: { error: I18n.t("blacklight.bookmarks.remove.failure") }
    else
      # Deprecated in Rails 5.0
      redirect_to :back, flash: { error: I18n.t("blacklight.bookmarks.remove.failure") }
    end
  end

  private
    def permit_bookmarks
      params.permit(bookmarks: [:document_id, :document_type])
    end
end
