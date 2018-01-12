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
    [ :disable_advanced_spellcheck ]


  def begins_with_search(solr_parameters)
    dereference_with(:append_start_flank, solr_parameters)
  end

  def exact_phrase_search(solr_parameters)
    dereference_with(:to_phrase, solr_parameters)
  end

  def disable_advanced_spellcheck(solr_parameters)
    params = get_params
    if !params.empty? && params["search_field"] == "advanced"
      # @See BL-234
      solr_parameters["spellcheck"] = "false"
    end
  end

  private

    def dereference_with(method, solr_parameters)
      query = solr_parameters["q"] || ""
      params = get_params

      # Search misbehaves if we alter non advanced search query.
      if !query.empty? && !params.empty? && params["search_field"] == "advanced"
        # We need the original values in the search for use in creating
        # a de-referenced version of the query.
        fields = get_params.select { |k| k.match(/^q_/) }

        # We de-reference values in order to be able to quote them; otherwise,
        # solr throws a 500 error: https://stackoverflow.com/a/10183238/256854
        #
        # First we generate something like:
        # [[["{}", "foo", "AND"], "q_1"], [["{}", "bar", "OR"], "q_2"]]
        # And then we map that to ["_query_:..", "_query_:..."]
        # @see :parse_queries, and :param_dereference methods below for more
        # details.
        queries = parse_queries(solr_parameters["q"])
          .zip(fields.keys)
          .map { |q, k| param_dereference(q, k) }
        solr_parameters["q"] = queries.join(" ")

        # De-referenced values have to be added as solr request parameters.
        ops = params.fetch("op_row", [])
        ops.zip(fields).each { |op, f|
          k, v = f
          solr_parameters[k] = send(method, v, op)
        }

      end
    end

    def append_start_flank(value, op)
      return if value.nil?

      # value is always fresh from params so we don't have to worry about
      # process duplication/mutation but we do have to reapply processes.
      if op == "begins_with"
        to_phrase("#{BEGINS_WITH_TAG} #{value}", "is")
      else
        value
      end
    end

    def to_phrase(value, op)
      return if value.nil?

      # value is always fresh from params so we don't have to worry about
      # process duplication/mutation but we do have to reapply processes.
      if op == "is"
        "\"#{value}\""
      elsif op == "begins_with"
        append_start_flank(value, op)
      else
        value
      end
    end

    # Given a blacklight solr query string in the form
    # "_query_:\"{}foo\" (AND|OR|NOT) (__query:\"{}bar\")..."
    # parses it to return an array of query components:
    # [["{}", "foo", AND], ["{}", "bar", nil]]
    def parse_queries(query_string)
      query_string.split("_query_:")
        .select { |q| q[0..1] == "\"{" }
        .map { |q| q.scan(/{(.*)}(.*)\".?(AND|OR|NOT)?/) }
        .map { |q| q.flatten }
    end

    # Given an array q representing the components of a single query:
    # i.e. ["{}", "foo", "AND"], generates a new string representation
    # of the query.
    # @see https://lucene.apache.org/solr/guide/6_6/local-parameters-in-queries.html
    # For details on local parameter dereferencing syntax.
    def param_dereference(q, k)
      local_param, _, connector = q
      "_query_:\"{#{local_param} v=$#{k}}\" #{connector}"
    end

    def get_params
      if scope.respond_to? :params
        scope.params || {}
      else
        {}
      end
    end
end
