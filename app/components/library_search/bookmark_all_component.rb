# frozen_string_literal: true

module LibrarySearch
  class BookmarkAllComponent < Blacklight::Component
    def initialize(documents:, document_type:)
      @documents = documents
      @document_type = document_type
    end

    def render?
      documents.present?
    end

    def all_bookmarked?
      bookmarked_count == documents.length
    end

    def form_url
      if all_bookmarked?
        helpers.bookmark_path(document_ids.first)
      else
        helpers.bookmarks_path
      end
    end

    def form_method
      all_bookmarked? ? :delete : :post
    end

    def button_label
      all_bookmarked? ? "Unbookmark&nbsp;all" : "Bookmark&nbsp;all"
    end

    attr_reader :documents, :document_type

    def document_ids
      @document_ids ||= documents.map(&:id)
    end

    private

      def bookmarked_count
        @bookmarked_count ||= helpers.current_or_guest_user&.bookmarks&.where(
          document_id: document_ids,
          document_type:
        )&.count || 0
      end
  end
end
