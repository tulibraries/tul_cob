# frozen_string_literal: true

class QueryListComponent < ViewComponent::Base
  def initialize(title:, tooltip:, query: "", footer_field: nil, document: nil)
    @title = title
    @tooltip = tooltip
    @query = query
    @footer_field = footer_field
    @document = document

    if @document&.id
      @query += "&filter_id=#{@document.id}"
    end

    if footer_field
      @query += "&footer_field=#{footer_field}"
    end
  end
end
