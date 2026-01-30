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
    @bookmarks = if params[:bookmarks]
      permit_bookmarks[:bookmarks]
    else
      [{ document_id: params[:id], document_type: blacklight_config.document_model.to_s }]
    end

    current_or_guest_user.save! unless current_or_guest_user.persisted?

    bookmarks_to_add = filter_existing_bookmarks(@bookmarks)
    success = ActiveRecord::Base.transaction do
      current_or_guest_user.bookmarks.create!(bookmarks_to_add) if bookmarks_to_add.any?
      true
    rescue ActiveRecord::RecordInvalid
      false
    end

    if request.xhr?
      success ? render(json: { bookmarks: { count: current_or_guest_user.bookmarks.count } }) : render(json: current_or_guest_user.errors.full_messages, status: "500")
    else
      if @bookmarks.any? && success
        flash[:notice] = I18n.t("blacklight.bookmarks.add.success", count: @bookmarks.length)
      elsif @bookmarks.any?
        flash[:error] = I18n.t("blacklight.bookmarks.add.failure", count: @bookmarks.length)
      end

      redirect_back fallback_location: bookmarks_path
    end

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

    def filter_existing_bookmarks(bookmarks)
      existing = existing_bookmark_ids_by_type(bookmarks)

      bookmarks.reject do |bookmark|
        doc_type = bookmark[:document_type] || bookmark["document_type"] || blacklight_config.document_model.to_s
        doc_id = (bookmark[:document_id] || bookmark["document_id"]).to_s
        existing.fetch(doc_type, {}).key?(doc_id)
      end
    end

    def existing_bookmark_ids_by_type(bookmarks)
      bookmarks
        .group_by { |bookmark| bookmark[:document_type] || bookmark["document_type"] }
        .each_with_object({}) do |(doc_type, items), memo|
          ids = items.map { |item| item[:document_id] || item["document_id"] }.compact
          next if ids.empty?

          existing_ids = current_or_guest_user.bookmarks.where(document_type: doc_type, document_id: ids).pluck(:document_id)
          memo[doc_type] = existing_ids.map(&:to_s).index_with(true)
        end
    end
end
