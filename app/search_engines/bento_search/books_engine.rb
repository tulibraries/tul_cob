# frozen_string_literal: true

module BentoSearch
  class BooksEngine < BlacklightEngine
    delegate :blacklight_config, to: BooksController

    def url(helper)
      helper.search_books_path(helper.params.except(:controller, :action))
    end

    def view_link(total = nil, helper)
      url = url(helper)
      helper.link_to "View all #{total} books", url, class: "full-results"
    end
  end
end
