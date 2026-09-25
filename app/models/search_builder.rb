# frozen_string_literal: true

require "blacklight_advanced_search/advanced_search_builder"

class SearchBuilder < Blacklight::SearchBuilder
  include Blacklight::Solr::SearchBuilderBehavior
  include BlacklightAdvancedSearch::AdvancedSearchBuilder
  include BlacklightRangeLimit::RangeLimitBuilder
  include BentoSearchBuilderBehavior
  include CobIndex::Macros::Wrapper

  self.default_processor_chain += %i[
    add_edismax_advanced_parse_q_to_solr
    add_advanced_search_to_solr
    add_lc_range_search_to_solr
    spellcheck
    filter_suppressed
    filter_id
    limit_facets
    sorting_preferences
  ]

  self.default_processor_chain += %i[ tweak_query ]

  MAX_QUERY_TOKENS = 20
  MAX_PHRASE_BOOST_TOKENS = 10
  MAX_CLAUSE_SAFE_TOKENS = 12
  MAX_CITATION_QUERY_TERMS = 12

  self.default_processor_chain += %i[
    truncate_overlong_search_query
    manage_long_queries_for_clause_limits
    normalize_def_type_for_simple_queries
  ]

  def add_edismax_advanced_parse_q_to_solr(solr_params)
    add_advanced_parse_q_to_solr(solr_params)

    unless is_advanced_search?
      solr_params.delete(:json)
      solr_params.delete("json")
    end

    q_key = solr_params.key?(:q) ? :q : "q"
    return unless solr_params[q_key].respond_to?(:to_str)

    q_op_key = solr_params.key?(:"q.op") ? :"q.op" : "q.op"
    return unless solr_params[q_key].include?("{!dismax")

    solr_params[q_key] = solr_params[q_key].gsub("{!dismax", "{!edismax")
    solr_params[q_op_key] = "OR"
  end

  def add_adv_search_clauses(solr_parameters)
    clause_params = search_state.clause_params
    return super if clause_params.present? && clause_params.size == 1

    clauses = advanced_search_clauses
    return if clauses.empty?

    queries = clauses.map { |clause| advanced_clause_query(clause) }
    query = queries.shift

    clauses.drop(1).zip(queries).each do |clause, clause_query|
      operator = clause["op"].presence || "must"
      query = case operator
              when "should"
                { bool: { should: [ query, clause_query ], minimum_should_match: 1 } }
              when "must_not"
                { bool: { must: [ query ], must_not: [ clause_query ] } }
              else
                { bool: { must: [ query, clause_query ] } }
      end
    end

    solr_parameters["json"] ||= {}
    solr_parameters["json"]["query"] = query
  end

  def add_facets_for_advanced_search_form(solr_parameters)
    super
    return unless is_advanced_search?
    return unless processed_search_params["q"].blank? && advanced_search_clauses.empty?

    solr_parameters.merge!(blacklight_config.advanced_search[:form_solr_parameters])
  end

  def filter_purchase_order(solr_params)
    # The negative query will work even when items are not indexed.
    # We can refactor to use a positive query once indexing occurs.
    solr_params["fq"] = solr_params["fq"].push("-purchase_order:true")
  end

  # TODO: Remove this once we update and use new tul_cob-catalog-solr config
  def filter_suppressed(solr_params)
    if !solr_params["fq"]&.include?("-suppress_items_b:true")
      solr_params["fq"] = (solr_params["fq"] || []).push("-suppress_items_b:true")
    end
  end

  def filter_id(solr_params)
    id = processed_search_params["filter_id"]

    if id.present? && !solr_params["fq"]&.include?("-id:#{id}")
      solr_params["fq"] = (solr_params["fq"] || []).push("-id:#{id}")
    end
  end

  def spellcheck(solr_parameters)
    if is_advanced_search?
      solr_parameters["spellcheck"] = false
    end
  end

  def is_advanced_search?
    search_state.controller&.action_name == "advanced_search" ||
      processed_search_params["search_field"] == blacklight_config.advanced_search[:url_key]
  end

  def limit_facets(solr_parameters)
    path = "#{processed_search_params["controller"]}/#{processed_search_params["action"]}"
    count = processed_search_params.keys.count

    # When only the controller and action are defined (count == 2), and the
    # controller is set to "catalog" and the action is set to "index", then we
    # are at the search page prior to doing a search.
    if path == "catalog/index" && count == 2
      solr_parameters["facet.field"] = [ "availability_facet", "library_facet", "format" ]
    elsif path == "catalog/range_limit"
      solr_parameters["facet.field"] = []
    elsif path == "catalog/advanced" || path == "catalog/advanced_search"
      solr_parameters["facet.field"] = blacklight_config.advanced_search[:form_solr_parameters]["facet.field"]
    elsif path.match?(/\/opensearch/) || path.match?(/\/query_list/)
      solr_parameters["facet"] = "off"
      solr_parameters["facet.field"] = []
    end
  end

  def sorting_preferences(solr_parameters)
    solr_parameters["f.lc_outer_facet.facet.sort"] = "index"
    solr_parameters["f.lc_inner_facet.facet.sort"] = "index"
  end

  def tweak_query(solr_parameters)
    return unless Flipflop.solr_query_tweaks?

    solr_parameters.merge!(processed_search_params.select { |name, value| name.match?(/(qf$|pf$)/) })
  end

  def truncate_overlong_search_query(solr_params)
    q_key = solr_params.key?("q") ? "q" : :q
    q = solr_params[q_key]
    return unless q.is_a?(String)
    return if id_fetch_query?(q)
    return if structured_advanced_query?(q)
    return if clause_limit_bug_fix_applicable?(q)

    tokens = q.split(/\s+/)
    return if tokens.length <= MAX_QUERY_TOKENS

    Rails.logger.info(
      "[SolrQueryTruncation] Truncating search query from #{tokens.length} to #{MAX_QUERY_TOKENS} tokens"
    )

    solr_params[q_key] = tokens.first(MAX_QUERY_TOKENS).join(" ")
  end

  def manage_long_queries_for_clause_limits(solr_params)
    q_key = solr_params.key?("q") ? "q" : :q
    q = solr_params[q_key]
    return unless q.is_a?(String)
    return if id_fetch_query?(q)
    return if structured_advanced_query?(q)

    tokens = q.delete("\"").split(/\s+/)
    return if tokens.empty?

    if tokens.length > MAX_PHRASE_BOOST_TOKENS
      clear_phrase_boost_params(solr_params)
    end

    return if tokens.length <= MAX_CLAUSE_SAFE_TOKENS

    if citation_like_query?(q)
      apply_citation_like_query_fallback(solr_params, q_key, q)
      return
    end

    phrase_query = strip_outer_quotes(q)
    escaped = phrase_query.gsub("\"", "\\\"")
    solr_params[q_key] = "\"#{escaped}\""

    df_key = if solr_params.key?("df")
      "df"
             elsif solr_params.key?(:df)
               :df
             else
               "df"
    end
    solr_params[df_key] = "text"

    qf_key = if solr_params.key?("qf")
      "qf"
             elsif solr_params.key?(:qf)
               :qf
             else
               "qf"
    end
    solr_params[qf_key] = "text"

    def_type_key = if solr_params.key?("defType")
      "defType"
                   elsif solr_params.key?(:defType)
                     :defType
                   else
                     "defType"
    end
    solr_params[def_type_key] = "lucene"
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

    df_key = if solr_params.key?("df")
      "df"
             elsif solr_params.key?(:df)
               :df
             else
               "df"
    end
    solr_params[df_key] ||= "text"

    def_type_key = if solr_params.key?("defType")
      "defType"
                   elsif solr_params.key?(:defType)
                     :defType
                   else
                     "defType"
    end
    solr_params[def_type_key] = "edismax"
  end

  def fully_quoted_query?(q)
    stripped = q.strip
    return false if stripped.length < 2

    %w[" '].include?(stripped[0]) && stripped[0] == stripped[-1]
  end

  def strip_outer_quotes(q)
    return q unless fully_quoted_query?(q)

    q.strip[1..-2]
  end

  def clear_phrase_boost_params(solr_params)
    %w[pf pf2 pf3].each do |param_name|
      string_key = param_name
      symbol_key = param_name.to_sym

      solr_params[string_key] = "" if solr_params.key?(string_key) || !solr_params.key?(symbol_key)
      solr_params[symbol_key] = "" if solr_params.key?(symbol_key)
    end
  end

  def citation_like_query?(q)
    return false if is_advanced_search?

    search_field = processed_search_params["search_field"]
    return false unless search_field.blank? || search_field == "all_fields"

    normalized = strip_outer_quotes(q.to_s)
    tokens = normalized.scan(/[[:alnum:]-]+/)
    return false if tokens.length <= MAX_CLAUSE_SAFE_TOKENS

    comma_count = normalized.count(",")
    semicolon_count = normalized.count(";")
    initial_count = normalized.scan(/\b[A-Z]\./).length
    author_segment_count = normalized.scan(/\b[[:alpha:]'-]+,\s*(?:[A-Z]\.\s*){1,}/).length
    has_year = normalized.match?(/\b(19|20)\d{2}\b/)

    (has_year && (comma_count >= 2 || initial_count >= 3)) ||
      semicolon_count >= 2 ||
      author_segment_count >= 3
  end

  def apply_citation_like_query_fallback(solr_params, q_key, q)
    terms = citation_like_terms(q)
    return if terms.empty?

    solr_params[q_key] = terms.join(" ")

    df_key = if solr_params.key?("df")
      "df"
             elsif solr_params.key?(:df)
               :df
             else
               "df"
    end
    solr_params[df_key] = "text"

    mm_key = if solr_params.key?("mm")
      "mm"
             elsif solr_params.key?(:mm)
               :mm
             else
               "mm"
    end
    solr_params[mm_key] = "3<75%"

    def_type_key = if solr_params.key?("defType")
      "defType"
                   elsif solr_params.key?(:defType)
                     :defType
                   else
                     "defType"
    end
    solr_params[def_type_key] = "edismax"
  end

  def citation_like_terms(q)
    normalized = strip_outer_quotes(q.to_s)
      .downcase
      .gsub(/&/, " ")
      .gsub(/[^[:alnum:]'\-\s]/, " ")
      .gsub(/\s+/, " ")
      .strip

    terms = normalized
      .split(" ")
      .reject { |term| term.length == 1 && term.match?(/\A[a-z]\z/) }
      .reject { |term| term == "'" }

    return terms.first(MAX_CITATION_QUERY_TERMS) unless (year_index = terms.index { |term| term.match?(/\A(19|20)\d{2}\z/) })

    author_terms = terms.first(year_index)
    title_terms = terms[(year_index + 1)..] || []

    prioritized_terms = author_terms.first(5) + [terms[year_index]] + title_terms.first(6)
    prioritized_terms.first(MAX_CITATION_QUERY_TERMS)
  end

  def clause_limit_bug_fix_applicable?(q)
    return false unless fully_quoted_query?(q)
    return false if is_advanced_search?

    search_field = processed_search_params["search_field"]
    return false unless search_field.blank? || search_field == "all_fields"

    q.delete("\"").split(/\s+/).length > MAX_CLAUSE_SAFE_TOKENS
  end

  # Returns the processed search parameters used by custom processors.
  def processed_search_params
    params = search_state.params.to_h.with_indifferent_access.deep_dup

    # This method needs to be idempotent.
    if params["processed"]
      params
    else
      process_params!(params, params_process_chain)
    end
  end

  def params_process_chain
    # These named procedures MUST take a value, and an operator as arguments
    # and return a value that can be processed by the next procedure on the
    # list.
    [ :process_call_number, :process_begins_with, :process_query, :sanitize_query, :substitute_special_chars]
  end

  def process_call_number(field: nil, value:, op: nil)
    return value unless "#{field}".match?(/call_number/)
    return value unless value.is_a?(String)

    normalized_value = normalize_call_number_query(value, op)

    payload = case op
              when "contains" then "*#{normalized_value}*"
              when "begins_with" then "#{normalized_value}*"
              else normalized_value
    end

    "{!lucene df=call_number_t allowLeadingWildcard=true}#{payload}"
  end

  def process_begins_with(field: nil, value:, op: nil)
    return value if value.blank?
    return value unless op == "begins_with"
    return value unless value.is_a?(String)
    return value if value.to_s.start_with?("{!")
    return value if field.to_s.match?(/call_number/)

    case field.to_s
    when "title_starts_with"
      normalized_value = normalize_alpha_sort_prefix(value)
      return value if normalized_value.blank?

      "#{normalized_value}*"
    else
      value
    end
  end

  def sanitize_query(field: nil, value:, op: nil)
    # Sanitize single quotes in the query
    if value&.start_with?("'") && value&.end_with?("'")
      value = value.sub(/^'/, '"').sub(/'$/, '"')
    end
    value
  end

  def process_query(field: nil, value:, op: nil)
    return if value.blank?
    return if value.class != String

    return value if value.to_s.start_with?("{!")
    return value if field.to_s.match?(/call_number/)

    # Process the query based on quote count and operation
    case value.scan(/"/).size

    when 1
      updated_value = value.sub(/"/, "")
      "\"#{updated_value}\""
    when ->(size) { size > 1 }
      value
    else
      case op
      when "is"
        "\"#{value}\""
      when "contains" then
        value.match?(/[?:]|\(\)/) ? "\"#{value}\"" : value
      else
        value
      end
    end
  end

  def substitute_special_chars(field: nil, value:, op: nil)
    return value if value.to_s.start_with?("{!")
    return value if field.to_s.match?(/call_number/)
    return value if field.to_s == "title_starts_with"
    return value if value.to_s.start_with?("\"") && value.to_s.end_with?("\"")

    value.gsub(/([:?]|\(\))/, " ") rescue value
  end

  def escape_call_number(value)
    collapsed = value.strip.gsub(/\s+/, " ")
    escaped_specials = collapsed.gsub(%r{([+\-!(){}\[\]^"~*?:\\/]|&&|\|\|)}) { "\\#{$1}" }
    escaped_specials.gsub(/\s+/, "\\ ")
  end

  def normalize_call_number_query(value, op)
    collapsed = value.strip.gsub(/\s+/, " ")

    if wildcard_separator_call_number?(collapsed, op)
      collapsed.downcase.scan(/[a-z0-9]+/).join("*")
    else
      escape_call_number(collapsed).downcase
    end
  end

  def wildcard_separator_call_number?(value, op)
    return false unless ["contains", "begins_with"].include?(op)
    return false if value.match?(/[.]/)

    tokens = value.scan(/[a-z0-9]+/i)
    return false unless tokens.length > 1

    first_token = tokens.first
    first_token.match?(/[a-z]/i) && first_token.match?(/\d/)
  end

  def normalize_alpha_sort_prefix(value)
    value.downcase.strip.gsub(/[^a-z]/, "")
  end

  def no_journals(solr_parameters)
    solr_parameters["fq"] = ["!format:Journal/Periodical"]
  end

  ##
  # Overrides Blacklight::Solr::SearchBuilderBehavior#add_facet_fq_to_solr in
  # order to skip faceting on unknown fields.
  #
  def add_facet_fq_to_solr(solr_parameters)
    facet_params = search_state.params["f"]
    if facet_params.respond_to?(:each_key)
      filtered_facet_params = facet_params.slice(*blacklight_config.facet_fields.keys)
      search_state.params["f"] = filtered_facet_params if filtered_facet_params.size != facet_params.size
    end

    super.tap do
      solr_parameters["fq"] = solr_parameters["fq"].uniq if solr_parameters["fq"].respond_to?(:uniq)
    end
  ensure
    search_state.params["f"] = facet_params if facet_params.respond_to?(:each_key)
  end

  def add_lc_range_search_to_solr(solr_params)
    solr_params["facet.field"]&.delete("lc_classification")

    return unless processed_search_params["range"] && processed_search_params["range"]["lc_classification"]

    lc_range = processed_search_params["range"]["lc_classification"]

    return if lc_range["begin"].blank? && lc_range["end"].blank?

    raw_begin = lc_range["begin"]
    raw_end = lc_range["end"]

    converted_begin = LcSolrSortable.convert(raw_begin) if raw_begin.present?
    converted_end = LcSolrSortable.convert(raw_end) if raw_end.present?

    return if converted_begin.blank? && converted_end.blank?

    converted_begin = "*" if converted_begin.blank?
    converted_end = "*" if converted_end.blank?

    solr_params["q"] = "*:*" if solr_params["q"].blank? && solr_params[:q].blank?

    solr_params["fq"] = Array(solr_params["fq"] || solr_params[:fq])
    solr_params["fq"] << "lc_call_number_sort: [#{converted_begin} TO #{converted_end}]"
  end

  private
    def id_fetch_query?(q)
      unique_key = blacklight_config.document_model.unique_key
      q.match?(/\A\{!lucene\}#{Regexp.escape(unique_key)}:\(/)
    end

    def structured_advanced_query?(q)
      is_advanced_search? && q.include?('_query_:"{!')
    end

    # Updates in place the query values in params by folding the named
    # procedures passed in through the values.
    #
    # @param [ActionController::Parameters] params Set of search parameters.
    # @param [Array] procedures A list of tokens denoting named procedures.
    # @see params_process_chain
    #
    def process_params!(params, procedures)
      params ||= {}
      procedures ||= []

      normalize_legacy_advanced_params!(params)

      if params["clause"].present?
        params["clause"].each_value do |clause|
          next unless clause.respond_to?(:[])
          next if clause["query"].blank?

          field = clause["field"]
          op = clause["match"] || clause[:match]
          value = clause["query"]

          if op == "begins_with" && field == "title"
            clause["field"] = "title_starts_with"
            field = clause["field"]
          end

          clause["query"] = procedures.reduce(value) { |current_value, procedure| send(procedure, field:, value: current_value, op:) }
        end
      end

      # Do not process non query values
      ops = normalized_query_operators(params)

      # query_key are like "q_1", "q_2"..., etc.
      # op is like "contains", "begins_with"..., etc.
      ops.each { |query_key, op|
        field_key = query_key.tr("q", "f")
        field = params[field_key]
        if op == "begins_with" && field == "title"
          params[field_key] = "title_starts_with"
          field = params[field_key]
        end
        value = params[query_key]

        # Fold the procedures onto the query value.
        params[query_key] = procedures.reduce(value) { |v, p| send(p, field:, value: v, op:) }
      }

      combine_title_begins_with_rows!(params, ops)

      params["processed"] = true

      params
    end

    def normalize_legacy_advanced_params!(params)
      return unless params["search_field"] == blacklight_config.advanced_search[:url_key]
      return if params["clause"].present?

      row_count = blacklight_config.advanced_search[:fields_row_count].presence || 3
      clauses = (1..row_count.to_i).filter_map do |index|
        query = params["q_#{index}"]
        next if query.blank?

        field = params["f_#{index}"]
        operators = params["operator"]
        match = if operators.is_a?(Array)
          operators[index - 1]
        else
          params.dig("operator", "q_#{index}")
        end
        match ||= "contains"
        op = params["op_#{index - 1}"] if index > 1

        {
          "field" => field,
          "query" => query,
          "match" => match,
          "op" => normalize_boolean_operator(op)
        }.compact
      end

      params["clause"] = clauses.each_with_index.to_h { |clause, index| [index.to_s, clause] } if clauses.present?
    end

    def advanced_search_clauses
      clauses = processed_search_params["clause"]
      return [] unless clauses.respond_to?(:each_value)

      clauses.each_value.filter { |clause| clause["query"].present? }
    end

    def advanced_clause_query(clause)
      parsed_clause = adv_search_clause(clause, "must")
      return parsed_clause.last if parsed_clause

      field = blacklight_config.search_fields[clause["field"]]
      parameters = field&.clause_params&.[](:edismax) || field&.solr_adv_parameters || field&.solr_parameters || {}
      { edismax: parameters.merge(query: clause["query"]) }
    end

    def normalize_boolean_operator(operator)
      case operator
      when "OR" then "should"
      when "NOT" then "must_not"
      when "AND" then "must"
      end
    end

    def combine_title_begins_with_rows!(params, ops)
      rows = ops.keys.sort.filter_map do |query_key|
        field_key = query_key.tr("q", "f")
        value = params[query_key]
        next if value.blank?
        next unless params[field_key] == "title_starts_with"
        next unless ops[query_key] == "begins_with"

        { query_key:, field_key:, value: }
      end

      return if rows.length < 2

      combined = rows.first[:value]

      rows.each_cons(2).with_index do |(_left, right), index|
        op_key = "op_#{index + 1}"
        op = params[op_key]
        next if op.blank? || op == "NOT"

        combined = "(#{combined}) #{op} (#{right[:value]})"
        params[right[:query_key]] = ""
      end

      params[rows.first[:query_key]] = combined
    end

    def normalized_query_operators(params)
      operators = params.fetch("operator", { "q" => "default" })

      case operators
      when Array
        operators.each_with_index.with_object({}) do |(value, index), normalized|
          normalized["q_#{index + 1}"] = value
        end
      else
        operators.select { |key, _value| key.match?(/^q/) }
      end
    end
end
