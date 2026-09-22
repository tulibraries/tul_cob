# frozen_string_literal: true

module Blacklight::PrimoCentral
  module SearchBuilderBehavior
    extend ActiveSupport::Concern

    def add_query_to_primo_central(primo_central_parameters)
      per_page = (search_state.params["per_page"] || blacklight_config.default_per_page).to_i
      page = (search_state.params["page"] || 1).to_i
      offset = (per_page * page) - per_page
      sort = search_state.params["sort"] || "rank"

      value = search_state.params[:q]
      value = "*" if value.nil? || value.empty?

      if value.is_a? Hash
        if value["pnxId"]&.is_a? Array
          # limit ids to 10 or API returns 0 results
          # (This is just a fail safe:)
          # (@see "./app/search_engines/primo_central_bookmark_search)
          queries = to_primo_id_queries(value["pnxId"][0, 10])
          primo_central_parameters[:query] = {
            limit: per_page,
            offset:,
            sort:,
            q: { value: queries },
          }
        else
          raise "FIXME, translation of Solr search for Summon"
        end
      elsif !search_state.params[:id].nil?
        primo_central_parameters[:query] = {
          limit: 1,
          offset: 0,
          q: {
            value: to_primo_id(search_state.params[:id]),
            precision: "contains",
          }
        }
      else
        primo_central_parameters[:query] = {
          limit: per_page,
          offset:,
          sort:,
          q: { value: }
        }
      end

      primo_central_parameters[:query].merge!(search_state.params.slice(:searchCDI, :pcAvailability))
    end

    def set_query_field(primo_central_parameters)
      field = to_primo_field(search_state.params[:search_field])

      # blacklight_range_limit can usurp this field for evil.
      if !blacklight_config.search_fields.keys.include?(field.to_s)
        field = "any"
      end

      primo_central_parameters[:query][:q][:field] = field
    end

    def previous_and_next_document(primo_central_parameters)
      if @start
        primo_central_parameters[:query][:offset] = @start
      end

      if  @rows
        primo_central_parameters[:query][:limit] = @rows
      end
    end

    def process_advanced_search(primo_central_parameters)
      if is_advanced_search?

        if search_state.params[:clause].present?
          return _process_blacklight8_advanced_form(primo_central_parameters)
        end

        rows_count = blacklight_config.advanced_search[:fields_row_count]

        build_query = (1..rows_count).map do |count|
          value = search_state.params["q_#{count}"]
          precision = search_state.params["operator_#{count}"]
          field = to_primo_field(search_state.params["f_#{count}"])
          operator = search_state.params["op_#{count}"]

          if !value&.empty? && !value.nil?
            { value:, field:, precision:, operator: }
          end
        end.compact

        primo_central_parameters[:query][:q][:value] = build_query unless build_query.empty?
      end
    end

    def _process_blacklight8_advanced_form(primo_central_parameters)
      clauses = search_state.params[:clause] || {}
      default_operator = search_state.params[:op] == "must" ? "AND" : "OR"
      use_clause_operators = search_state.params[:op].blank?

      build_query = clauses.map.with_index { |(_, clause), index|
        field = to_primo_field(clause[:field] || clause["field"])
        value = clause[:query] || clause["query"]
        precision = clause[:match] || clause["match"] || "contains"
        operator = if use_clause_operators && index.positive?
          to_primo_boolean_operator(clause[:op] || clause["op"])
        else
          default_operator
        end

        if !value&.empty? && !value.nil?
          { value:, field:, precision:, operator: }
        end
      }.compact
      primo_central_parameters[:query][:q][:value] = build_query unless build_query.empty?
    end

    def to_primo_boolean_operator(operator)
      case operator
      when "should" then "OR"
      when "must_not" then "NOT"
      else "AND"
      end
    end

    # Query is a Primo::Search::Query instance after this process.
    def add_query_facets(primo_central_parameters)
      if primo_central_parameters[:query][:q][:value].is_a? Array
        op = :build
        query = primo_central_parameters[:query][:q][:value]
      else
        op = :new
        query = primo_central_parameters[:query][:q]
      end

      pq = Primo::Search::Query.send(op, query)
      pq.facet({
        field: "rtype",
        value: "books",
        operation: :exclude
      })

      primo_central_parameters[:query][:q] = pq

      search_state.params.fetch(:f, {})
        .merge(search_state.params.fetch(:f_inclusive, {}))
        .each do |field, values|
          # Only facet known fields
          next unless blacklight_config.facet_fields[field.to_s].present?
          values.each do |value|
            primo_central_parameters[:query][:q].facet(
              field: solr_to_primo_facet(field),
              value:
            )
          end
        end
    end

    def process_date_range_query(primo_central_parameters)
      params = search_state.params

      min = params.dig("range", "creationdate", "begin")
      max = params.dig("range", "creationdate", "end")
      range = YearRange.new(min, max)
      primo_central_parameters[:range] = range

      # Adding the date range facet prematurely causes search discrepencies.
      if (min.present? || max.present?)
        primo_central_parameters[:query][:q].date_range_facet(min:, max:)
      end
    end

    private
      class YearRange
        attr_reader :min, :max

        def initialize(min = nil, max = nil)
          @min = min unless min.blank?
          @max = max unless max.blank?
        end
      end

      def to_primo_id_queries(values)
        values.map { |v|
          {
            field: :any,
            value: to_primo_id(v),
            precision: :contains,
            operator: :OR,
          }
        }
      end

      def to_primo_id(value)
        "'#{value.gsub(/^TN_/, "")
          .gsub("-dot-", ".")
          .gsub("-slash-", "/")
          .gsub("-semicolon-", ";")
          }'"
      end

      def to_primo_field(field)
        configed_fields
          .merge(
            all_fields: :any,
            advanced: :any,
            creator_t: :creator,
            isbn_t: :isbn,
            issn_t: :issn,
            subject: :sub,
            description: :desc,)
          .with_indifferent_access
          .fetch(field, :any)
      end

      def is_advanced_search?
        search_state.controller&.action_name == "advanced_search" ||
          !(@scope.advanced_query.nil? || @scope.advanced_query.keyword_queries.empty? rescue false)
      end

      def configed_fields
        search_fields = blacklight_config.search_fields.keys.map(&:to_sym)
        @configed_fields ||= Hash[*search_fields.zip(search_fields).flatten]
      end
  end
end
