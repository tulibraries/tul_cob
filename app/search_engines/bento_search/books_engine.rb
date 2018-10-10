# frozen_string_literal: true

module BentoSearch
  class BooksEngine < BlacklightEngine
    delegate :blacklight_config, to: BooksController

    def url(helper)
      params = helper.params
      helper.search_books_path(q: params[:q])
    end

    def view_link(total = nil, helper)
      url = url(helper)
      helper.link_to "View all #{total} books", url, class: "full-results"
    end
  end
end
