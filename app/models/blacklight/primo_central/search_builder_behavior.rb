# frozen_string_literal: true

module Blacklight::PrimoCentral
  module SearchBuilderBehavior
    extend ActiveSupport::Concern

    included do
        self.default_processor_chain = [
            :add_query_to_primo_central,
            :add_query_facets,
        ]
      end

    def add_query_to_primo_central(primo_central_parameters)
      per_page = (blacklight_params["per_page"] || blacklight_config.default_per_page).to_i
      page = (blacklight_params["page"] || 1).to_i
      offset = (per_page * page) - per_page
      value = blacklight_params[:q]

      if value.is_a? Hash
        raise "FIXME, translation of Solr search for Summon"
      elsif value
        primo_central_parameters[:query] = {
          limit: per_page,
          offset:  offset,
          q: { field: :any, value: value }
        }
      else
        primo_central_parameters[:query] = {
          q: { field: :any, value: value },
        }
      end
    end

    def add_query_facets(primo_central_parameters)
      q = Primo::Pnxs::Query.new primo_central_parameters[:query][:q]
      primo_central_parameters[:query][:q] = q

      blacklight_params.fetch(:f, {}).each do |field, values|
        values.each do |value|
          primo_central_parameters[:query][:q].facet(
            field: field,
            value: value
          )
        end
      end
    end
  end
end
