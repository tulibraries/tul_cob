# frozen_string_literal: true

class PrimoAdvancedController < PrimoCentralController
  copy_blacklight_config_from(PrimoCentralController)

  add_breadcrumb "Articles", :back_to_articles_path
  add_breadcrumb I18n.t(:articles_advanced_search), :articles_advanced_search_path,
    only: [ :index ]
end
