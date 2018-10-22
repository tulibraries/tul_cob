# frozen_string_literal: true

class BooksAdvancedController < AdvancedController
  copy_blacklight_config_from(BooksController)

  add_breadcrumb "Books", :back_to_books_path
  add_breadcrumb I18n.t(:books_advanced_search), :books_advanced_search_path,
    only: [ :index ]

  protected
    def search_action_url(options = {})
      books_advanced_search_path(options.merge(action: "index"))
    end
end
