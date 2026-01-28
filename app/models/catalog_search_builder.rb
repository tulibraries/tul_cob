# frozen_string_literal: true

class CatalogSearchBuilder < SearchBuilder
  MAX_QUERY_TOKENS = 20
  MAX_PHRASE_BOOST_TOKENS = 10
  MAX_CLAUSE_SAFE_TOKENS = 12

  self.default_processor_chain += [
    :force_query_parser_for_advanced_search,
    :truncate_overlong_search_query,
    :manage_long_queries_for_clause_limits,
    :normalize_def_type_for_simple_queries
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

    def manage_long_queries_for_clause_limits(solr_params)
      q = solr_params[:q]
      return unless q.is_a?(String)

      tokens = q.split(/\s+/)
      return if tokens.empty?

      if tokens.length > MAX_PHRASE_BOOST_TOKENS
        solr_params.delete("pf")
        solr_params.delete("pf2")
        solr_params.delete("pf3")
      end

      return if tokens.length <= MAX_CLAUSE_SAFE_TOKENS

      escaped = q.gsub("\"", "\\\"")
      solr_params[:q] = "\"#{escaped}\""
      solr_params[:defType] = "lucene"
    end

    def force_query_parser_for_advanced_search(solr_params)
      return unless is_advanced_search?

      solr_params["df"] ||= "text"
      solr_params["defType"] = "lucene"
    end

    def normalize_def_type_for_simple_queries(solr_params)
      return if is_advanced_search?

      q = solr_params["q"] || solr_params[:q]
      return unless q.is_a?(String)

      return if q.start_with?("{!") || q.include?("_query_:")

      tokens = q.delete('"').split(/\s+/)
      return if tokens.length > MAX_CLAUSE_SAFE_TOKENS

      def_type = solr_params["defType"] || solr_params[:defType]
      return unless def_type.to_s == "lucene"

      solr_params["df"] ||= "text"
      solr_params["defType"] = "edismax"
    end
end
