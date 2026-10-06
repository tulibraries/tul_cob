# frozen_string_literal: true

class DatabasesSearchBuilder < SearchBuilder
  # Override multi-clause advanced searches to preserve Solr field substitutions for databases.
  def add_adv_search_clauses(solr_parameters)
    clause_params = search_state.clause_params
    return super if clause_params.present? && clause_params.size == 1

    clauses = send(:advanced_search_clauses)
    return if clauses.empty?

    solr_parameters["q"] = parsed_advanced_query(clauses)
    solr_parameters["defType"] = "lucene"
    solr_parameters["q.op"] = "OR" if solr_parameters["q"].include?("{!edismax")
    solr_parameters.delete("json")
  end

  private

    def parsed_advanced_query(clauses)
      queries = clauses.map { |clause| parsed_advanced_clause_query(clause) }
      query = queries.shift

      clauses.drop(1).zip(queries).each do |clause, clause_query|
        operator = clause["op"].presence || "must"
        query = case operator
                when "should"
                  "( #{query} OR #{clause_query} )"
                when "must_not"
                  "( #{query} AND NOT #{clause_query} )"
                else
                  "( #{query} AND #{clause_query} )"
        end
      end

      query
    end

    def parsed_advanced_clause_query(clause)
      field = blacklight_config.search_fields[clause["field"]]
      parameters = field&.solr_adv_parameters || field&.solr_parameters || {}
      parsed = ParsingNesting::Tree.parse(
        clause["query"],
        blacklight_config.advanced_search[:query_parser]
      ).to_single_query_params(parameters)
      parsed_query = parsed[:q] || parsed["q"]
      parsed_query&.gsub("{!dismax", "{!edismax")&.gsub("{!qf=", "{!edismax qf=") || clause["query"]
    rescue Parslet::ParseFailed
      clause["query"]
    end
end
