# frozen_string_literal: true

class SearchBuilder < Blacklight::SearchBuilder
  include Blacklight::Solr::SearchBuilderBehavior
  include BlacklightAdvancedSearch::AdvancedSearchBuilder
  include BlacklightRangeLimit::RangeLimitBuilder
  include BentoSearchBuilderBehavior
  include CobIndex::Macros::Wrapper

  self.default_processor_chain +=
    %i[ add_advanced_parse_q_to_solr
        add_advanced_search_to_solr
        add_lc_range_search_to_solr
        spellcheck
        filter_suppressed
        filter_id
        limit_facets
        sorting_preferences ]

  if ENV["SOLR_SEARCH_TWEAK_ENABLE"] == "on"
    self.default_processor_chain += %i[ tweak_query ]
  end

  MAX_QUERY_TOKENS = 20
  MAX_PHRASE_BOOST_TOKENS = 10
  MAX_CLAUSE_SAFE_TOKENS = 12

  self.default_processor_chain += %i[
    force_query_parser_for_advanced_search
    truncate_overlong_search_query
    manage_long_queries_for_clause_limits
    normalize_def_type_for_simple_queries
  ]

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
    id = blacklight_params["filter_id"]

    if id.present? && !solr_params["fq"]&.include?("-id:#{id}")
      solr_params["fq"] = (solr_params["fq"] || []).push("-id:#{id}")
    end
  end

  def spellcheck(solr_parameters)
    if is_advanced_search?
      solr_parameters["spellcheck"] = false
    end
  end

  def limit_facets(solr_parameters)
    path = "#{blacklight_params["controller"]}/#{blacklight_params["action"]}"
    count = blacklight_params.keys.count

    # When only the controller and action are defined (count == 2), and the
    # controller is set to "catalog" and the action is set to "index", then we
    # are at the search page prior to doing a search.
    if path == "catalog/index" && count == 2
      solr_parameters["facet.field"] = [ "availability_facet", "library_facet", "format" ]
    elsif path == "catalog/range_limit" || path == "catalog/advanced"
      solr_parameters["facet.field"] = []
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
    solr_parameters.merge!(blacklight_params.select { |name, value| name.match?(/(qf$|pf$)/) })
  end

  def truncate_overlong_search_query(solr_params)
    q_key = solr_params.key?("q") ? "q" : :q
    q = solr_params[q_key]
    return unless q.is_a?(String)
    return if id_fetch_query?(q)

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

    tokens = q.split(/\s+/)
    return if tokens.empty?

    if tokens.length > MAX_PHRASE_BOOST_TOKENS
      solr_params.delete("pf")
      solr_params.delete("pf2")
      solr_params.delete("pf3")
      solr_params.delete(:pf)
      solr_params.delete(:pf2)
      solr_params.delete(:pf3)
    end

    return if tokens.length <= MAX_CLAUSE_SAFE_TOKENS

    escaped = q.gsub("\"", "\\\"")
    solr_params[q_key] = "\"#{escaped}\""

    def_type_key = if solr_params.key?("defType")
      "defType"
                   elsif solr_params.key?(:defType)
                     :defType
                   else
                     "defType"
    end
    solr_params[def_type_key] = "lucene"
  end

  def force_query_parser_for_advanced_search(solr_params)
    return unless is_advanced_search?

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

  # Overrides Blacklight::SearchBuilder#blacklight_params
  #
  # We need to do this because so much of what advanced_search is doing depends
  # on it and currently there isn't a cleaner way beyond overriding it.
  #
  # @see projectblacklight/blacklight_advanced_search#82
  def blacklight_params
    params = super

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

    normalized_value = escape_call_number(value).downcase

    payload = case op
              when "contains" then "*#{normalized_value}*"
              when "begins_with" then "#{normalized_value}*"
              else normalized_value
    end

    "{!lucene df=call_number_t allowLeadingWildcard=true}#{payload}"
  end

  def process_begins_with(field: nil, value:, op: nil)
    value
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
      else
        value
      end
    end
  end

  def substitute_special_chars(field: nil, value:, op: nil)
    return value if value.to_s.start_with?("{!")
    return value if field.to_s.match?(/call_number/)

    value.gsub(/([:?]|\(\))/, " ") rescue value
  end

  def escape_call_number(value)
    collapsed = value.strip.gsub(/\s+/, " ")
    escaped_specials = collapsed.gsub(%r{([+\-!(){}\[\]^"~*?:\\/]|&&|\|\|)}) { "\\#{$1}" }
    escaped_specials.gsub(/\s+/, "\\ ")
  end

  def no_journals(solr_parameters)
    solr_parameters["fq"] = ["!format:Journal/Periodical"]
  end

  ##
  # Overrides Blacklight::Solr::SearchBuilderBehavior#add_facet_fq_to_solr in
  # order to skip faceting on unknown fields.
  #
  def add_facet_fq_to_solr(solr_parameters)
    # convert a String value into an Array
    if solr_parameters[:fq].is_a? String
      solr_parameters[:fq] = [solr_parameters[:fq]]
    end
    # :fq, map from :f.
    if blacklight_params[:f]
      blacklight_params[:f].each_pair do |facet_field, value_list|
        next unless blacklight_config.facet_fields.map { |k, v|
          v.pivot ? v.pivot : k }.flatten.include? facet_field.to_s
        Array(value_list).reject(&:blank?).each do |value|
          solr_parameters.append_filter_query facet_value_to_fq_string(facet_field, value)
        end
      end
    end
  end

  def add_lc_range_search_to_solr(solr_params)
    # Solr throws exceptions when trying to facet unnknown fields.
    solr_params["facet.field"].delete("lc_classification")

    return unless blacklight_params["range"] && blacklight_params["range"]["lc_classification"]

    lc_range = blacklight_params["range"]["lc_classification"]

    return if lc_range["begin"].blank? && lc_range["end"].blank?

    raw_begin = lc_range["begin"]
    raw_end   = lc_range["end"]

    _begin = LcSolrSortable.convert(raw_begin) if raw_begin.present?
    _end   = LcSolrSortable.convert(raw_end)   if raw_end.present?

    _begin = "*" if _begin.blank?
    _end   = "*" if _end.blank?

    (solr_params[:fq] || []) << "lc_call_number_sort: [#{_begin} TO #{_end}]"
  end

  private
    def id_fetch_query?(q)
      unique_key = blacklight_config.document_model.unique_key
      q.match?(/\A\{!lucene\}#{Regexp.escape(unique_key)}:\(/)
    end

    # Updates in place the query values in params by folding the named
    # procedures passed in through the values.
    #
    # @param [ActionController::Parameters] params Set of search parameters.
    # @param [Array] procedures A list of tokens denoting named procedures.
    # @see params_process_chain
    #
    # @return [ActionController::Parameters] The updated set of search parameters.
    def process_params!(params, procedures)
      params ||= {}
      procedures ||= []
      params["processed"] = true

      # Do not process non query values
      ops = params.fetch("operator", "q" => "default")
        .select { |key, value| key.match?(/^q/) }

      # query_key are like "q_1", "q_2"..., etc.
      # op is like "contains", "begins_with"..., etc.
      ops.each { |query_key, op|

        field = params[query_key.tr("q", "f")]
        value = params[query_key]

        # Fold the procedures onto the query value.
        params[query_key] = procedures.reduce(value) { |v, p| send(p, field:, value: v, op:) }
      }
      params
    end
end
