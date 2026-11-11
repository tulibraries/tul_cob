# frozen_string_literal: true

module PermittedSearchParams
  extend ActiveSupport::Concern

  MAX_ADVANCED_SEARCH_CLAUSES = 10
  MAX_FACET_VALUES = 50
  ADVANCED_SEARCH_MATCHES = %w[contains is begins_with].freeze
  ADVANCED_SEARCH_OPERATORS = %w[AND OR NOT].freeze

  def permit_search_parameters
    raw_parameters = ActionController::Parameters.new(request.parameters)
    if raw_parameters.key?(:f) && !raw_parameters[:f].respond_to?(:to_h)
      render plain: "Invalid request", status: :bad_request, content_type: "text/plain"
      return
    end

    search_state = Blacklight::SearchState.new(
      raw_parameters,
      blacklight_config
    )
    # SearchState has already applied search_state_fields and facet-field filtering;
    # permit! marks this bounded copy safe for the downstream search workflow.
    normalized = normalize_search_parameters(search_state.to_h)
    normalized[:sort] = normalize_sort_parameter(raw_parameters[:sort]) if raw_parameters[:sort].respond_to?(:each_pair)
    @permitted_search_params = ActionController::Parameters.new(normalized).permit!
  end

  def params
    @permitted_search_params || super
  end

  private

    def normalize_search_parameters(parameters)
      normalized = parameters.with_indifferent_access.deep_dup
      normalized[:f] = normalize_facet_parameters(normalized[:f]) if normalized[:f]
      normalized[:range] = normalize_range_parameters(normalized[:range]) if normalized[:range]
      normalized[:clause] = normalize_clause_parameters(normalized[:clause]) if normalized[:clause]
      normalized[:operator] = normalize_operator_parameters(normalized[:operator]) if normalized[:operator]
      normalized[:sort] = normalize_sort_parameter(normalized[:sort]) if normalized[:sort]
      normalized[:"facet.field"] = normalize_facet_fields(normalized[:"facet.field"]) if normalized[:"facet.field"]
      normalized
    end

    def normalize_facet_parameters(value)
      return {} unless value.respond_to?(:each_pair)

      value.each_pair.each_with_object({}) do |(field, values), facets|
        next unless field.to_s.in?(facet_field_names)

        facets[field.to_s] = Array(values).uniq.first(MAX_FACET_VALUES)
      end
    end

    def normalize_range_parameters(value)
      return {} unless value.respond_to?(:each_pair)

      allowed_fields = (facet_field_names + %w[lc_classification pub_date_sort]).uniq
      value.each_pair.each_with_object({}) do |(field, range), ranges|
        next unless field.to_s.in?(allowed_fields) && range.respond_to?(:each_pair)

        ranges[field.to_s] = range.to_h.stringify_keys.slice("begin", "end")
      end
    end

    def normalize_clause_parameters(value)
      return {} unless value.respond_to?(:each_pair)

      value.each_pair.first(MAX_ADVANCED_SEARCH_CLAUSES).each_with_object({}) do |(index, clause), clauses|
        next unless clause.respond_to?(:each_pair)

        clause = clause.to_h.stringify_keys.slice("field", "query", "match", "op")
        next unless clause["field"].to_s.in?(search_field_names)
        next if clause["match"].present? && !clause["match"].to_s.in?(ADVANCED_SEARCH_MATCHES)
        next if clause["op"].present? && !clause["op"].to_s.in?(ADVANCED_SEARCH_OPERATORS + %w[must should must_not])

        clauses[index.to_s] = clause
      end
    end

    def normalize_operator_parameters(value)
      return {} unless value.respond_to?(:each_pair)

      value.each_pair.each_with_object({}) do |(key, operator), operators|
        next unless key.to_s.match?(/\Aq_\d+\z/)
        next unless operator.to_s.in?(ADVANCED_SEARCH_MATCHES)

        operators[key.to_s] = operator.to_s
      end
    end

    def normalize_sort_parameter(value)
      if value.respond_to?(:each_pair)
        allowed_sort_fields = blacklight_config.sort_fields.keys.flat_map do |sort_field|
          sort_field.to_s.scan(/\b[\w.]+(?=\s+(?:asc|desc)\b)/)
        end.uniq + [ "lc_call_number_sort" ]

        return value.each_pair.each_with_object({}) do |(field, direction), sorts|
          next unless field.to_s.in?(allowed_sort_fields)
          next unless direction.to_s.in?(%w[asc desc true false])

          sorts[field.to_s] = direction
        end
      end

      return unless value.respond_to?(:to_s)

      allowed_sort_fields = blacklight_config.sort_fields.keys.map(&:to_s) + [ "lc_call_number_sort" ]
      value.to_s if value.to_s.in?(allowed_sort_fields)
    end

    def normalize_facet_fields(value)
      Array(value).select { |field| field.to_s.in?(facet_field_names) }.first(MAX_FACET_VALUES)
    end

    def facet_field_names
      blacklight_config.facet_fields.keys.map(&:to_s)
    end

    def search_field_names
      blacklight_config.search_fields.keys.map(&:to_s)
    end
end
