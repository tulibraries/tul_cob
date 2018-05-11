# frozen_string_literal: true

#require "primo"

module Blacklight::PrimoCentral
  class Repository < Blacklight::AbstractRepository
    def find(id, params = {})
      duration = duratin_for(:article_record_cache_life)
      response = Rails.cache.fetch("articles/show/#{id}", expires_in: duration) do
        id = id.gsub("-dot-", ".")
          .gsub("-slash-", "/")
        # We convert to hash because we cannot serialize the Primo response.
        # @see https://github.com/rails/rails/issues/7375
        Primo.find(id: id).to_h
      end
      blacklight_config.document_model.new response.to_h
    end

    ##
    # Execute a search against Summon
    #
    def search(params = {})
      data = params[:query]
      duration = duration_for(:article_search_cache_life)
      response = Rails.cache.fetch("articles/index/#{data}", expires_in: duration) do
        # We convert to hash because we cannot serialize the Primo response.
        # @see https://github.com/rails/rails/issues/7375
        Primo.find(data).to_h
      end

      response_opts = {
        facet_counts: response["facets"].length,
        numFound: response["info"]["total"],
        document_model: blacklight_config.document_model,
        blacklight_config: blacklight_config,
      }.with_indifferent_access

      blacklight_config.response_model.new(response, data, response_opts)
    end

    private

      def duration_for(cache_name)
        delta = Rails.configuration.caches[cache_name]
        ActiveSupport::Duration.parse(delta)
      end
  end
end
