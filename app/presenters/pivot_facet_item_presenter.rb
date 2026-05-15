# frozen_string_literal: true

class PivotFacetItemPresenter < Blacklight::FacetItemPivotPresenter
  def label
    return location_label if facet_field == "library_facet" && nested?

    super
  end

  def items
    items = super || []
    if facet_field == "library_facet"
      items = items.select do |item|
        item_value = item.value.to_s
        !item_value.include?(" - ") || item_value.start_with?("#{value} - ")
      end

      items.each do |item|
        item_value = item.value.to_s
        item.label = item_value.include?(" - ") ? item_value.split(" - ", 2).last : item_value
      end
    end

    items
  end

  def has_selected_child?
    return false if facet_item.is_a?(String) || @parent_facet_item || facet_config.pivot.nil?

    facet_item_presenters.any?(&:selected?)
  end

  def remove_href(path = search_state)
    if has_selected_child?
      path_hash = path.to_h.deep_dup
      path_hash[:f]&.delete(items.first.field)
      path_hash.delete(:f) if path_hash[:f]&.empty?
      search_path(path_hash)
    else
      updated_state = path.filter(facet_config).remove(facet_item)
      path_hash = updated_state.to_h.deep_dup
      if @parent_facet_item && parent_field_values(path_hash, @parent_facet_item.field).present?
        path_hash[:f][@parent_facet_item.field] = Array(path_hash[:f][@parent_facet_item.field]).reject do |selected_value|
          selected_value == @parent_facet_item.value
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
    @parent_facet_item.present?
  end

  def constraint_label
    return @constraint_label_override if defined?(@constraint_label_override) && @constraint_label_override.present?

    label
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

  def facet_item_presenter(child_facet_item)
    presenter = self.class.new(child_facet_item, facet_config, view_context, facet_field, search_state)
    presenter.parent = facet_item
    presenter
  end

  private

  def location_label
    label_source = facet_item.respond_to?(:label) ? facet_item.label : value
    item_value = label_source.presence || value

    item_value.to_s.include?(" - ") ? item_value.to_s.split(" - ", 2).last : item_value.to_s
  end

  def parent_field_values(params_hash, field)
    Array(params_hash.dig(:f, field))
  end
end
