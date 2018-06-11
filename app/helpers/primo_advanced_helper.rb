# frozen_string_literal: true

module PrimoAdvancedHelper
  def articles_advanced_search_link
    if current_page?(articles_advanced_search_path)
      link_to "Basic Search", search_path, class: "advanced_search"
    else
      link_to "Advanced Articles Search", articles_advanced_search_path(search_state.to_h), class: "advanced_search"
    end
  end
end
