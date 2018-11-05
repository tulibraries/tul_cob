# frozen_string_literal: true

class ArticleNotFound < RuntimeError
end

module Blacklight::PrimoCentral
  class Repository < Blacklight::AbstractRepository
    def find(id, params = {})
      id = id.gsub("-dot-", ".")
        .gsub("-slash-", "/")
        .gsub("-semicolon-", ";")
      search(query: { id: id })
    end

    # Execute a search against Primo PNXS API.
    def search(params = {})
      data = params[:query]

      duration =
        if data[:id]
          duration_for(:article_record_cache_life)
        else
          duration_for(:article_search_cache_life)
        end

      response = Rails.cache.fetch("articles/index/#{data}", expires_in: duration) do
        # We convert to hash because we cannot serialize the Primo response.
        # @see https://github.com/rails/rails/issues/7375
        start = Time.now
        response = Primo.find(data).to_h
        LogUtils.json_request_logger(logger, { type: "primo_search", start: start }.merge(data.dup))
        response
      end

      response_opts = {
        facet_counts: 0,
        numFound: 1,
        document_model: blacklight_config.document_model,
        blacklight_config: blacklight_config,
      }.with_indifferent_access

      if !data[:id]
        response_opts.merge!(
          facet_counts: response["facets"].length,
          numFound: response["info"]["total"]
        )
        data[:range] = params[:range] || {}
      else
        if response.count == 1
          raise ArticleNotFound
        end
      end

      blacklight_config.response_model.new(response, data, response_opts)
    end

    private

      def duration_for(cache_name)
        # Do not bring down site due to a parse error.
        begin
          delta = Rails.configuration.caches[cache_name]
          ActiveSupport::Duration.parse(delta)
        rescue
          logger.error("Error: Failed to parse ISO-8601 formated duration,#{delta}")
          12.hours
        end
      end
  end
end
