# frozen_string_literal: true

class BooksAdvancedController < AdvancedController
  copy_blacklight_config_from(BooksController)

  protected
    def search_action_url(options = {})
      books_advanced_search_path(options.merge(action: "index"))
    end
end
