# frozen_string_literal: true

require "primo"

module Blacklight::PrimoCentral
  class Repository < Blacklight::AbstractRepository
    def find(id, params = {})
      search params.merge(id: id, fields: blacklight_config.show_fields.values)
    end


    ##
    # Execute a search against Summon
    #
    def search(params = {})
      params = params.to_hash

      primo_response = Primo.find(params.fetch(:q, ""))
      Rails.logger.info "Primo searched with query #{params.fetch(:q, '')} in #{primo_response.timelog.BriefSearchDeltaTime / 1000.0} seconds"
      data = primo_response

      response_opts = {
          facet_counts: primo_response.facets.length,
          numFound: primo_response.info.total,
          document_model: blacklight_config.document_model,
          blacklight_config: blacklight_config
      }.with_indifferent_access

      blacklight_config.response_model.new(data, params, response_opts)
    end
  end
end
