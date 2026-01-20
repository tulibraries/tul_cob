# frozen_string_literal: true

class CatalogSearchBuilder < SearchBuilder
  MAX_QUERY_TOKENS = 20
  MAX_PHRASE_BOOST_TOKENS = 10

  self.default_processor_chain += [
    :truncate_overlong_search_query,
    :disable_phrase_boosts_for_long_queries
  ]

  private

    def truncate_overlong_search_query(solr_params)
      q = solr_params[:q]
      return unless q.is_a?(String)

      tokens = q.split(/\s+/)
      return if tokens.length <= MAX_QUERY_TOKENS

      Rails.logger.info(
        "[SolrQueryTruncation] Truncating search query from #{tokens.length} to #{MAX_QUERY_TOKENS} tokens"
      )

      solr_params[:q] = tokens.first(MAX_QUERY_TOKENS).join(" ")
    end

    def disable_phrase_boosts_for_long_queries(solr_params)
      q = solr_params[:q]
      return unless q.is_a?(String)

      token_count = q.split(/\s+/).length
      return if token_count <= MAX_PHRASE_BOOST_TOKENS

      solr_params.delete("pf")
      solr_params.delete("pf2")
      solr_params.delete("pf3")
    end
end
