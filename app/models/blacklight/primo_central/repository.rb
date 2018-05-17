# frozen_string_literal: true

#require "primo"

module Blacklight::PrimoCentral
  class Repository < Blacklight::AbstractRepository
    def find(id, params = {})
      id = id.gsub("-dot-", ".")
        .gsub("-slash-", "/")
      search(query: { id: id })
    end

    ##
    # Execute a search against Summon
    #
    def search(params = {})
      data = params[:query]
      response = Primo.find(data)

      response_opts = {
        facet_counts: 0,
        numFound: 1,
        document_model: blacklight_config.document_model,
        blacklight_config: blacklight_config,
      }.with_indifferent_access

      if !data[:id]
        response_opts.merge!(
          facet_counts: response.facets.length,
          numFound: response.info.total,
        )
      end

      blacklight_config.response_model.new(response, data, response_opts)
    end
  end
end
