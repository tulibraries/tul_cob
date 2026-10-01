# frozen_string_literal: true

# Search parameters retain Blacklight's query shape while limiting fields, nesting, and collection sizes.
module PermittedSearchParams
  extend ActiveSupport::Concern

  SEARCH_PARAMETER_KEYS = %w[
    action
    controller
    commit
    defType
    df
    facet
    facet.limit
    facet.offset
    facet.prefix
    facet.sort
    field
    fl
    filter_id
    format
    id
    page
    per_page
    pf
    pf2
    pf3
    processed
    q
    q.op
    qf
    rows
    search_field
    sort
    start
    utf8
    view
    wt
  ].freeze

  MAX_ADVANCED_SEARCH_CLAUSES = 10
  MAX_FACET_VALUES = 50
  ADVANCED_SEARCH_PARAMETER = /\A(?:q|f|op)_(\d+)\z/
  ADVANCED_SEARCH_MATCHES = %w[contains is begins_with].freeze
  ADVANCED_SEARCH_OPERATORS = %w[AND OR NOT].freeze

  def permit_search_parameters
    raw_parameters = request_parameters_hash
    if raw_parameters.key?("f") && !raw_parameters["f"].respond_to?(:to_h)
      render plain: "Invalid request", status: :bad_request, content_type: "text/plain"
      return
    end

    permitted = ActionController::Parameters.new(
      raw_parameters.slice(*(permitted_search_parameter_keys + dynamic_search_parameter_keys(raw_parameters)))
    ).permit(*(permitted_search_parameter_keys + dynamic_search_parameter_keys(raw_parameters)))
    remove_invalid_advanced_search_parameters(permitted)

    assign_search_parameter(permitted, "facet.field", raw_parameters["facet.field"])
    assign_search_parameter(permitted, "f", permitted_facet_parameters(raw_parameters["f"]))
    assign_search_parameter(permitted, "range", permitted_range_parameters(raw_parameters["range"]))
    assign_search_parameter(permitted, "clause", permitted_clause_parameters(raw_parameters["clause"]))
    assign_search_parameter(permitted, "operator", permitted_operator_parameters(raw_parameters["operator"]))
    assign_search_parameter(permitted, "sort", permitted_sort_parameters(raw_parameters["sort"]))

    @permitted_search_params = permitted
  end

  def params
    @permitted_search_params || super
  end

  private

    def request_parameters_hash
      parameters = request.parameters
      # Read the request container without trusting it; the bounded allowlist is applied immediately below.
      parameters = parameters.to_unsafe_h if parameters.respond_to?(:to_unsafe_h)
      parameters = parameters.to_h if parameters.respond_to?(:to_h)
      parameters.stringify_keys
    end

    def permitted_search_parameter_keys
      SEARCH_PARAMETER_KEYS + search_parameter_extra_keys + facet_parameter_keys
    end

    def search_parameter_extra_keys
      []
    end

    def facet_parameter_keys
      facet_field_names.flat_map do |field|
        [
          "f.#{field}.facet.limit",
          "f.#{field}.facet.offset",
          "f.#{field}.facet.sort"
        ]
      end
    end

    def dynamic_search_parameter_keys(raw_parameters)
      raw_parameters.keys.filter_map do |key|
        match = key.match(ADVANCED_SEARCH_PARAMETER)
        next unless match && match[1].to_i.between?(1, MAX_ADVANCED_SEARCH_CLAUSES)

        key
      end
    end

    def facet_field_names
      blacklight_config.facet_fields.keys.map(&:to_s)
    end

    def search_field_names
      blacklight_config.search_fields.keys.map(&:to_s)
    end

    def remove_invalid_advanced_search_parameters(parameters)
      dynamic_search_parameter_keys(parameters.to_h).each do |key|
        next unless parameters[key]

        if key.start_with?("f_") && !parameters[key].to_s.in?(search_field_names)
          parameters.delete(key)
        elsif key.start_with?("op_") && !parameters[key].to_s.in?(ADVANCED_SEARCH_OPERATORS)
          parameters.delete(key)
        end
      end
    end

    def permitted_facet_parameters(value)
      return unless value.respond_to?(:to_h)

      values = value.to_h.stringify_keys
        .slice(*facet_field_names)
        .transform_values { |facet_values| Array(facet_values).uniq.first(MAX_FACET_VALUES) }

      ActionController::Parameters.new(values).permit(*values.keys.map { |key| { key => [] } })
    end

    def permitted_range_parameters(value)
      return unless value.respond_to?(:to_h)

      range_field_names = (facet_field_names + %w[lc_classification pub_date_sort]).uniq
      values = value.to_h.stringify_keys.slice(*range_field_names)
      values = values.transform_values do |range|
        next unless range.respond_to?(:to_h)

        range.to_h.stringify_keys.slice("begin", "end")
      end.compact

      ActionController::Parameters.new(values).permit(*values.keys.map { |key| { key => %i[begin end] } })
    end

    def permitted_clause_parameters(value)
      return unless value.respond_to?(:to_h)

      values = value.to_h.stringify_keys.slice(*(0...MAX_ADVANCED_SEARCH_CLAUSES).map(&:to_s))
      values = values.each_with_object({}) do |(index, clause), permitted_values|
        next unless clause.respond_to?(:to_h)

        clause = clause.to_h.stringify_keys.slice("field", "query", "match", "op")
        next unless clause["field"].to_s.in?(search_field_names)
        next if clause["match"].present? && !clause["match"].to_s.in?(ADVANCED_SEARCH_MATCHES)
        next if clause["op"].present? && !clause["op"].to_s.in?(ADVANCED_SEARCH_OPERATORS + %w[must should must_not])

        permitted_values[index] = clause
      end

      ActionController::Parameters.new(values).permit(*values.keys.map { |key| { key => %i[field query match op] } })
    end

    def permitted_operator_parameters(value)
      if value.is_a?(Array)
        value = value.first(MAX_ADVANCED_SEARCH_CLAUSES).each_with_index.to_h { |operator, index| ["q_#{index + 1}", operator] }
      end
      return unless value.respond_to?(:to_h)

      values = value.to_h.stringify_keys.slice(*value.to_h.stringify_keys.keys.grep(/\Aq_\d+\z/).first(MAX_ADVANCED_SEARCH_CLAUSES))
      values.select! { |_key, operator| operator.to_s.in?(ADVANCED_SEARCH_MATCHES) }
      ActionController::Parameters.new(values).permit(*values.keys)
    end

    def permitted_sort_parameters(value)
      return value unless value.respond_to?(:to_h)

      allowed_keys = blacklight_config.sort_fields.keys.map(&:to_s) + ["lc_call_number_sort"]
      values = value.to_h.stringify_keys.slice(*allowed_keys)
      ActionController::Parameters.new(values).permit(*values.keys)
    end

    def assign_search_parameter(parameters, key, value)
      return if value.blank?

      if key == "facet.field"
        values = Array(value).select { |field| field.to_s.in?(facet_field_names) }.first(MAX_FACET_VALUES)
        parameters[key] = values if values.present?
      elsif value.respond_to?(:permitted?)
        parameters[key] = value
      elsif !%w[f range clause operator].include?(key)
        parameters[key] = value
      end
    end
end
