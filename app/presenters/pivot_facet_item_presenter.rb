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

    items.sort_by! do |item|
      case facet_config.pivot.last.to_s
      when "lc_inner_facet"
        item.value.to_s.downcase
      else
        [selected_facet_value?(item.field, item.value) ? 0 : 1, -item.hits.to_i, item.value.to_s]
      end
    end

    items
  end

  def selected?
    field = facet_item.respond_to?(:field) ? facet_item.field : facet_field
    return selected_facet_value?(field) if nested?
    return true if super
    return false unless facet_config.pivot

    selected_facet_value?(field)
  end

  def href(path_options = {})
    return remove_href if selected?
    return add_href(path_options) if nested?

    super
  end

  def add_href(path_options = {})
    return super unless nested?

    updated_state = search_state.add_facet_params_and_redirect(facet_config.key, facet_item)
    path_hash = updated_state.to_h.deep_dup
    parent_field = facet_config.pivot.first.to_sym
    parent_value = parent_facet_value
    facet_params = path_hash[:f] || path_hash["f"]
    if parent_value && facet_params
      parent_key = facet_params.key?(parent_field) ? parent_field : parent_field.to_s
      facet_params[parent_key] = Array(facet_params[parent_key]).reject { |value| value == parent_value }
      facet_params.delete(parent_key) if facet_params[parent_key].blank?
    end
    search_path(path_hash.merge(path_options))
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
    @parent_facet_item.present? ||
      (facet_config.pivot.present? && facet_item.respond_to?(:field) && facet_item.field.to_s == facet_config.pivot.last.to_s)
  end

  def parent_facet_value
    return @parent_facet_item.value if @parent_facet_item
    return unless facet_item.respond_to?(:fq)

    facet_item.fq.to_h.fetch(facet_config.pivot.first.to_sym) do
      facet_item.fq.to_h[facet_config.pivot.first.to_s]
    end
  end

  def selected_facet_value?(field, item_value = value)
    params = search_state.params
    facet_params = params.dig(:f) || params.dig("f") || {}
    selected_values = facet_params[field] || facet_params[field.to_s]

    Array(selected_values).include?(item_value)
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
