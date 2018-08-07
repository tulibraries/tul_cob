# frozen_string_literal: true

module PrimoAdvancedHelper
  def articles_advanced_search_link
    if current_page?(articles_advanced_search_path)
      link_to "Basic Search", search_path, class: "advanced_search", id: "articles_basic_search"
    else
      params = @search_state.to_h.select { |k, v| !["page"].include? k }
      link_to "Advanced Articles Search", articles_advanced_search_path(params), class: "advanced_search", id: "articles_advanced_search"
    end
  end
end
