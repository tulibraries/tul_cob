# frozen_string_literal: true

module Blacklight::PrimoCentral
  module SearchBuilderBehavior
    extend ActiveSupport::Concern

    def add_query_to_primo_central(primo_central_parameters)
      per_page = (blacklight_params["per_page"] || blacklight_config.default_per_page).to_i
      page = (blacklight_params["page"] || 1).to_i
      offset = (per_page * page) - per_page

      value = blacklight_params[:q]
      value = "*" if value.nil? || value.empty?

      if value.is_a? Hash
        if value["pnxId"]&.is_a? Array
          # limit ids to 9 or API returns 0 results
          queries = to_primo_id_queries(value["pnxId"][0, 9])
          primo_central_parameters[:query] = {
            limit: per_page,
            offset:  offset,
            q: { value: queries },
          }
        else
          raise "FIXME, translation of Solr search for Summon"
        end
      else
        primo_central_parameters[:query] = {
          limit: per_page,
          offset:  offset,
          q: { value: value }
        }
      end
    end

    def set_query_field(primo_central_parameters)
      field = to_primo_field(blacklight_params[:search_field])
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

    def set_query_sort_order(primo_central_parameters)
    end

    def process_advanced_search(primo_central_parameters)
      if is_advanced_search?
        rows_count = @scope.helpers.advanced_search_config[:fields_row_count]

        build_query = (1..rows_count).map do |count|
          value = blacklight_params["q_#{count}"]
          precision = blacklight_params["operator_#{count}"]
          field = blacklight_params["f_#{count}"]
          operator = blacklight_params["op_#{count}"] || "AND"

          if !value&.empty? && !value.nil?
            { value: value, field: field, precision: precision, operator: operator }
          end
        end.compact

        primo_central_parameters[:query][:q][:value] = build_query unless build_query.empty?
      end
    end

    # This needs to come last as it instantiates the pnxs query.
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
        values.each do |value|
          primo_central_parameters[:query][:q].facet(
            field: solr_to_primo_facet(field),
            value: value
          )
        end
      end
    end

    private
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
          .gsub("-", " ")}'"
      end

      def to_primo_field(field)
        {
          all_fields: :any,
          creator_t: :creator,
          isbn_t: :isbn,
          issn_t: :issn,
          subject: :sub,
        }
          .with_indifferent_access
          .fetch(field, field) || :any
      end

      def is_advanced_search?
        blacklight_params[:controller] == "primo_advanced" ||
          blacklight_params[:q_1]
      end
  end
end
