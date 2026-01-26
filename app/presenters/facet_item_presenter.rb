# frozen_string_literal: true

class FacetItemPresenter < Blacklight::FacetItemPresenter
  def items
    items = super || []
    if facet_field == "library_facet"
      # Filter out secondary facets that do not match library
      items = items.select { |i| i.value.match?(/#{value}/) }
      # Add proper secondary facet labels
      items.each { |i| i.label = i.value.split(" - ", 2).last }
    end
    return items
  end

  def has_selected_child?
    return false if facet_item.is_a?(String) || @parent_facet_item || facet_config.pivot.nil?
    items && items.size > 0 && items.any? { |item| search_state.filter([item.field]) && search_state&.filter(item.field).include?(item.value) }
  end

  def remove_href(path = search_state)
    if has_selected_child?
      path_hash = path.to_h.deep_dup
      path_hash[:f]&.delete(items[0].field)
      path_hash.delete(:f) if path_hash[:f]&.empty?
      search_path(path_hash)
    else
      updated_state = path.filter(facet_config.key).remove(facet_item)
      path_hash = updated_state.to_h.deep_dup
      if @parent_facet_item && parent_field_values(path_hash, @parent_facet_item.field).present?
        path_hash[:f][@parent_facet_item.field] = Array(path_hash[:f][@parent_facet_item.field]).reject do |value|
          value == @parent_facet_item.value
        end
        path_hash[:f].delete(@parent_facet_item.field) if path_hash[:f][@parent_facet_item.field].blank?
        path_hash.delete(:f) if path_hash[:f].blank?
      end
      search_path(path_hash)
    end
  end

  def search_path(path)
    context = if view_context.respond_to?(:search_action_path)
      view_context
    elsif view_context.respond_to?(:helpers) && view_context.helpers.respond_to?(:search_action_path)
      view_context.helpers
    elsif view_context.respond_to?(:view_context) && view_context.view_context.respond_to?(:search_action_path)
      view_context.view_context
    else
      view_context
    end
    context.search_action_path(path)
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
      return search_state&.filter(field).include?(value)
    end
    return false
  end

  def constraint_label
    return @constraint_label_override if defined?(@constraint_label_override) && @constraint_label_override.present?

    super
  end

  def constraint_label_override=(value)
    @constraint_label_override = value
  end

  def constraint_classes
    @constraint_classes ||= []
  end

  def add_constraint_class(class_name)
    return if class_name.blank?

    constraint_classes << class_name
  end

  private

  def parent_field_values(params_hash, field)
    Array(params_hash.dig(:f, field))
  end
end
