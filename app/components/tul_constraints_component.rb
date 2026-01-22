# frozen_string_literal: true

require "ostruct"

class TulConstraintsComponent < Blacklight::ConstraintsComponent
  def initialize(**kwargs)
    kwargs[:facet_constraint_component] ||= TulConstraintComponent
    super(**kwargs)
  end

  private

  def facet_item_presenters
    return to_enum(:facet_item_presenters) unless block_given?

    @search_state.filters.each do |facet|
      facet.each_value do |val|
        next if val.blank?

        presenter = constraint_presenter_for(facet.config, val, facet.key)
        next if omit_facet_constraint?(facet.key, presenter, val)

        decorate_presenter(presenter, facet.key, val)
        yield presenter
      end
    end
  end

  def decorate_presenter(presenter, field, value)
    case field.to_s
    when "lc_inner_facet"
      append_lc_parent(presenter)
    when "location_facet"
      attach_library_parent(presenter, value)
    when "library_facet"
      hide_parent_if_child_selected(presenter, value)
    end
  end

  def append_lc_parent(presenter)
    parent_value = selected_values("lc_outer_facet").first
    return if parent_value.blank?

    return unless presenter.respond_to?(:parent=)

    presenter.parent = OpenStruct.new(field: "lc_outer_facet", value: parent_value)
    if presenter.respond_to?(:constraint_label_override=)
      presenter.constraint_label_override = "#{parent_value} | #{presenter.constraint_label}"
    end
  end

  def attach_library_parent(presenter, value)
    return if selected_values("library_facet").blank?

    parent_value = normalize_filter_value(value).to_s.split(" - ").first
    return if parent_value.blank?

    return unless presenter.respond_to?(:parent=)

    presenter.parent = OpenStruct.new(field: "library_facet", value: parent_value)
  end

  def hide_parent_if_child_selected(presenter, value)
    return if selected_values("location_facet").blank?

    parent_label = normalize_filter_value(value).to_s
    return if parent_label.blank?

    if selected_values("location_facet").any? { |loc| loc.match?(/#{Regexp.escape(parent_label)}/) }
      presenter.add_constraint_class("hidden") if presenter.respond_to?(:add_constraint_class)
    end
  end

  def omit_facet_constraint?(field, presenter = nil, value = nil)
    case field.to_s
    when "lc_facet"
      true
    when "lc_outer_facet"
      selected_values("lc_inner_facet").present?
    when "library_facet"
      location_selected_for?(value)
    else
      false
    end
  end

  def location_selected_for?(value)
    selected_values("location_facet").any? do |loc|
      loc.match?(/#{Regexp.escape(normalize_filter_value(value).to_s)}/)
    end
  end

  def selected_values(field)
    params = @search_state.respond_to?(:params) ? @search_state.params : @search_state
    return [] unless params

    values = params.dig(:f, field) || params.dig("f", field)
    Array.wrap(values).compact.map { |val| normalize_filter_value(val) }.reject(&:blank?)
  end

  def normalize_filter_value(value)
    return if value.nil?

    if value.respond_to?(:value)
      normalize_filter_value(value.value)
    elsif value.is_a?(Hash)
      normalize_filter_value(value[:value] || value["value"])
    else
      value.to_s
    end
  end

  def constraint_presenter_for(facet_config, facet_item, facet_field)
    if constraint_presenter_fields.include?(facet_field.to_s)
      ::FacetItemPresenter.new(facet_item, facet_config, helpers, facet_field)
    else
      facet_item_presenter(facet_config, facet_item, facet_field)
    end
  end

  def constraint_presenter_fields
    %w[library_facet location_facet lc_inner_facet]
  end

  def location_facet_configured?
    helpers.blacklight_config&.facet_fields&.key?("location_facet")
  end
end
