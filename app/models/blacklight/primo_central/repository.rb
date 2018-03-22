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
      data = params[:query]
      response = Primo.find(data)

      Rails.logger.info "Primo searched with query #{params[:q]} in #{response.timelog.BriefSearchDeltaTime / 1000.0} seconds"

      blacklight_config[:q] = ""
      response_opts = {
          facet_counts: response.facets.length,
          numFound: response.info.total,
          document_model: blacklight_config.document_model,
          blacklight_config: blacklight_config,
      }.with_indifferent_access

      blacklight_config.response_model.new(response, data, response_opts)
    end
  end
end
