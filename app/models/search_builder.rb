# frozen_string_literal: true

class SearchBuilder < Blacklight::SearchBuilder
  include Blacklight::Solr::SearchBuilderBehavior
  include BlacklightAdvancedSearch::AdvancedSearchBuilder
  include BlacklightRangeLimit::RangeLimitBuilder

  BEGINS_WITH_TAG = "matchbeginswith"
  ENDS_WITH_TAG = "matchendswith"

  self.default_processor_chain +=
    %i[add_advanced_parse_q_to_solr add_advanced_search_to_solr ] +
    # Process order matters; :begins_with_search assumes :exact_phrase_search
    # happens after it, see the note for :to_phrase method for extra context.
    [ :begins_with_search ] +
    [ :exact_phrase_search ] +
    [ :disable_advanced_spellcheck ] +
    [ :substitute_colons ] +
    [ :normalize_and_search ]


  def begins_with_search(solr_parameters)
    dereference_with(:append_start_flank, solr_parameters)
  end

  def exact_phrase_search(solr_parameters)
    dereference_with(:to_phrase, solr_parameters)
  end

  def disable_advanced_spellcheck(solr_parameters)
    if blacklight_params["search_field"] == "advanced"
      # @See BL-234
      solr_parameters["spellcheck"] = "false"
    end
  end

  def substitute_colons(solr_parameters)
    query = solr_parameters["q"] || ""

    return unless !query.empty?

    # In the advanced the query is dereferenced.
    if blacklight_params["search_field"] == "advanced"
      fields.each { |k, v| solr_parameters[k] = v.gsub(/:/, " ") }
    else
      solr_parameters["q"] = query.gsub(/:/, " ")
    end
  end

  def normalize_and_search(solr_parameters)
    query = solr_parameters["q"] || ""

    return unless !query.empty?

    # In the advanced the query is dereferenced.
    if blacklight_params["search_field"] == "advanced"
      fields.each { |k, v| solr_parameters[k] = v.gsub(/ & /, " and ") }
    else
      solr_parameters["q"] = query.gsub(/ & /, " and ")
    end
  end

  private

    def dereference_with(method, solr_parameters)
      query = solr_parameters["q"] || ""

      # Search misbehaves if we alter non advanced search query.
      if !query.empty? && blacklight_params["search_field"] == "advanced"
        # We need the original values in the search for use in creating
        # a de-referenced version of the query.
        #
        # We de-reference values in order to be able to quote them; otherwise,
        # solr throws a 500 error: https://stackoverflow.com/a/10183238/256854
        #
        # First we take the query string and generate something like:
        # [[["AND _query_:", "foo", "bar"], "q_1"], [["OR _query_:", "biz", "buz"], "q_2"]]
        # And then we transform and rejoin that into a dereferenced query:
        #
        # "AND _query_:\"{foo v=$q_1}\" OR _query_:\"{biz v=$q_2}\""
        #
        # @see :parse_queries, and :param_dereference methods below for more
        # details.
        queries = parse_queries(solr_parameters["q"])
          .zip(fields.keys)
          .map { |q, k| param_dereference(q, k) }

        solr_parameters["q"] = queries.join(" ")

        # De-referenced values have to be added as solr request parameters.
        # TODO: move to it's own preprocessor
        ops = blacklight_params.fetch("op_row", [])
        ops.zip(fields).each { |op, f|
          k, v = f
          # REF BL-253
          # advanced_search moves prefix BOOLEAN to query connector.
          v = v.gsub(/^\s*(AND NOT|OR|NOT|AND)\s*/, "") unless v.nil?
          solr_parameters[k] = send(method, v, op)
        }

      end
    end

    def fields
      blacklight_params.select { |k| k.match(/^q_/) }
    end

    def append_start_flank(value, op)
      return if value.nil?

      # value is always fresh from blacklight_params so we don't have to worry
      # about process duplication/mutation but we do have to reapply processes.
      if op == "begins_with"
        to_phrase("#{BEGINS_WITH_TAG} #{value}", "is")
      else
        value
      end
    end

    def to_phrase(value, op)
      return if value.nil?

      # value is always fresh from blacklight_params so we don't have to worry
      # about process duplication/mutation but we do have to reapply processes.
      if op == "is"
        "\"#{value}\""
      elsif op == "begins_with"
        append_start_flank(value, op)
      else
        value
      end
    end

    # Given a blacklight solr query string in the form
    # "AND _query_:\"{foo} bar\" NOT _query:\"{biz} buz\""
    # splits it into its components (connector, local params, query)
    # ["AND _query_:", "foo", "bar"], ["NOT", "biz", "buz"]]
    def parse_queries(query_string)
      query_string ||= ""
      query_string
        .scan(/((AND NOT|OR|NOT|AND)?\s*_query_:\"{.*?}.*?\")/)
        .map { |q, _| q.scan(/(.*)\"{(.*)}(.*)\"/) }
        .map(&:flatten)
    end

    # Given an array representing the components of a single query, and
    # a parameter key: i.e. ["AND _query_:", "foo", "bar"], key
    # generates dereferenced representation of the query.
    #
    # "AND _query_:\"{foo v=$key}\""
    #
    # @see https://lucene.apache.org/solr/guide/6_6/local-parameters-in-queries.html
    # For details on local parameter dereferencing syntax.
    def param_dereference(q, k)
      connector, local_param, _ = q
      "#{connector}\"{#{local_param} v=$#{k}}\""
    end
end
