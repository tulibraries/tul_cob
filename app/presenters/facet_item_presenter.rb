# frozen_string_literal: true

class FacetItemPresenter < Blacklight::FacetItemPresenter
  def items
    items = super
    if facet_field == "library_pivot_facet"
      items = items.select { |i| i.value.match?(/#{facet_value}/) }
      items.each { |i| i.label = i.value.split(" - ", 2).reject { |j| j.blank? }.last }
    end
    return items
  end

  def has_selected_child?
    return false if facet_item.is_a?(String) || @parent_facet_item || facet_config.pivot.nil?
    items && items.size == 1 && search_state.filter_params[items[0].field] && search_state.filter_params[items[0].field].include?(items[0].value)
  end

  def remove_href(path = search_state)
    if has_selected_child?
      path_hash = path.remove_facet_params(nil, nil)
      path_hash["f"]&.delete(items[0].field)
      search_path(path_hash)
    else
      path_hash = path.remove_facet_params(facet_config.key, facet_item)
      if @parent_facet_item && path_hash.dig("f", @parent_facet_item.field)
        path_hash["f"][@parent_facet_item.field] = path_hash["f"][@parent_facet_item.field].reject { |value|
          value == @parent_facet_item.value
        }
      end
      search_path(path_hash)
    end
  end

  def search_path(path)
    view_context.search_action_path(path)
  end

  def parent=(parent_facet_item)
    @parent_facet_item = parent_facet_item
  end

  def nested?
    @parent_facet_item ? true : false
  end

  def selected?
    return true if super
    if facet_config.pivot
      field = facet_item.respond_to?(:field) ? facet_item.field : facet_field
      return search_state.has_facet? view_context.facet_configuration_for_field(field), value: facet_value
    end
    return false
  end
end
