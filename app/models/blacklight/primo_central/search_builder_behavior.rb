# frozen_string_literal: true

module Blacklight::PrimoCentral
  module SearchBuilderBehavior
    extend ActiveSupport::Concern

    def add_query_to_primo_central(primo_central_parameters)
      per_page = (blacklight_params["per_page"] || blacklight_config.default_per_page).to_i
      page = (blacklight_params["page"] || 1).to_i
      offset = (per_page * page) - per_page
      sort = blacklight_params["sort"] || "rank"

      value = blacklight_params[:q]
      value = "*" if value.nil? || value.empty?

      if value.is_a? Hash
        if value["pnxId"]&.is_a? Array
          # limit ids to 13 or API returns 0 results
          queries = to_primo_id_queries(value["pnxId"][0, 13])
          primo_central_parameters[:query] = {
            limit: per_page,
            offset:  offset,
            sort: sort,
            q: { value: queries },
          }
        else
          raise "FIXME, translation of Solr search for Summon"
        end
      elsif !blacklight_params[:id].nil?
        primo_central_parameters[:query] = {
          limit: 1,
          offset: 0,
          q: {
            value: to_primo_id(blacklight_params[:id]),
            precision: "contains",
          }
        }
      else
        primo_central_parameters[:query] = {
          limit: per_page,
          offset:  offset,
          sort: sort,
          q: { value: value }
        }
      end
    end

    def set_query_field(primo_central_parameters)
      field = to_primo_field(blacklight_params[:search_field])

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
        rows_count = blacklight_config.advanced_search[:fields_row_count]

        build_query = (1..rows_count).map do |count|
          value = blacklight_params["q_#{count}"]
          precision = blacklight_params["operator_#{count}"]
          field = to_primo_field(blacklight_params["f_#{count}"])
          operator = blacklight_params["op_#{count}"]

          if !value&.empty? && !value.nil?
            { value: value, field: field, precision: precision, operator: operator }
          end
        end.compact

        primo_central_parameters[:query][:q][:value] = build_query unless build_query.empty?
      end
    end

    # Query is a Primo::Pnxs::Query instance after this process.
    def add_query_facets(primo_central_parameters)
      if primo_central_parameters[:query][:q][:value].is_a? Array
        op = :build
        query = primo_central_parameters[:query][:q][:value]
      else
        op = :new
        query = primo_central_parameters[:query][:q]
      end

      pq = Primo::Pnxs::Query.send(op, query)

      primo_central_parameters[:query][:q] = pq

      blacklight_params.fetch(:f, {})
        .merge(blacklight_params.fetch(:f_inclusive, {}))
        .each do |field, values|
        # Only facet known fields
        next unless blacklight_config.facet_fields[field.to_s].present?
        values.each do |value|
          primo_central_parameters[:query][:q].facet(
            field: solr_to_primo_facet(field),
            value: value
          )
        end
      end
    end

    def process_date_range_query(primo_central_parameters)
      params = blacklight_params

      min = params.dig("range", "creationdate", "begin")
      max = params.dig("range", "creationdate", "end")
      range = YearRange.new(min, max)
      primo_central_parameters[:range] = range

      # Adding the date range facet prematurely causes search discrepencies.
      if (min || max)
        primo_central_parameters[:query][:q].date_range_facet(min: min, max: max)
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
        {
          all_fields: :any,
          advanced: :any,
          creator_t: :creator,
          isbn_t: :isbn,
          issn_t: :issn,
          subject: :sub,
          description: :desc,
        }
          .with_indifferent_access
          .fetch(field, :any)
      end

      def is_advanced_search?
        blacklight_params[:controller] == "primo_advanced" ||
          !(@scope.advanced_query.nil? || @scope.advanced_query.keyword_queries.empty? rescue false)
      end
  end
end
