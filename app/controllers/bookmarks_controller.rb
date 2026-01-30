# frozen_string_literal: true

class BookmarksController < CatalogController
  include Blacklight::Bookmarks

  # Overridden to not cache.
  def index
    no_cache
    return super unless request.format.csv?

    load_csv_bookmarks

    respond_to do |format|
      format.csv { render }
    end
  end

  def create
    super
    set_guest_bookmark_warning
  end

  def destroy
    super
    set_guest_bookmark_warning
  end

  def action_documents
    return super unless params[:id].present?

    document_ids = Array(params[:id]).map(&:to_s)
    search_service.fetch(document_ids, rows: document_ids.length, start: 0)
  end

  private

    def load_csv_bookmarks
      document_ids = bookmark_ids_for_csv

      if document_ids.empty?
        @response = Blacklight::Solr::Response.new({ "response" => { "docs" => [] } }, {})
        @document_list = []
        return
      end

      unique_key = blacklight_config.document_model.unique_key
      escaped_ids = document_ids.map { |id| RSolr.solr_escape(id.to_s) }

      repository = search_service.repository
      @response = repository.search(
        q: "*:*",
        fq: "{!terms f=#{unique_key}}#{escaped_ids.join(",")}",
        rows: document_ids.length
      )
      @document_list = @response.documents
    end

    def bookmark_ids_for_csv
      user = if respond_to?(:token_or_current_or_guest_user)
        token_or_current_or_guest_user
             else
               current_or_guest_user
      end
      bookmarks = user.bookmarks
      document_type = blacklight_config.document_model.to_s

      if bookmarks.respond_to?(:where)
        return bookmarks.where(document_type: document_type).pluck(:document_id)
      end

      Array(bookmarks)
        .select { |bookmark| bookmark.document_type == document_type }
        .map(&:document_id)
    end

    def set_guest_bookmark_warning
      return if request.xhr? || current_user.present?

      flash.discard(:notice)
      flash.discard(:error)
      flash[:alert] = I18n.t("blacklight.bookmarks.guest_warning")
    end
end
