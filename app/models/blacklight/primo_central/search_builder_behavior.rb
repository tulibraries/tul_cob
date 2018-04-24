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
        raise "FIXME, translation of Solr search for Summon"
      elsif value
        primo_central_parameters[:query] = {
          limit: per_page,
          offset:  offset,
          q: { value: value }
        }
      else
        primo_central_parameters[:query] = {
          q: { value: value },
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

    def add_query_facets(primo_central_parameters)
      q = Primo::Pnxs::Query.new primo_central_parameters[:query][:q]
      primo_central_parameters[:query][:q] = q

      blacklight_params.fetch(:f, {}).each do |field, values|
        values.each do |value|
          primo_central_parameters[:query][:q].facet(
            field: solr_to_primo_facet(field),
            value: value
          )
        end
      end
    end

    private

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
  end
end
