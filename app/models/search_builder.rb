# frozen_string_literal: true

class SearchBuilder < Blacklight::SearchBuilder
  include Blacklight::Solr::SearchBuilderBehavior
  include BlacklightAdvancedSearch::AdvancedSearchBuilder
  include BlacklightRangeLimit::RangeLimitBuilder

  BEGINS_WITH_TAG = "matchbeginswith"
  ENDS_WITH_TAG = "matchendswith"

  self.default_processor_chain +=
    %i[ add_advanced_parse_q_to_solr
        add_advanced_search_to_solr
        limit_facets ]

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
    end
  end

  # Overrides Blacklight::SearchBuilder#blacklight_params
  #
  # We need to do this because so much of what advanced_search is doing depends
  # on it and currenlty there isn't a cleaner way beyond overriding it.
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
    [ :process_begins_with, :process_is, :substitute_colons ]
  end

  def process_begins_with(value, op)
    return if value.nil?

    if op == "begins_with"
      value = process_is("#{BEGINS_WITH_TAG} #{value}", "is")
      value
    else
      value
    end
  end

  def process_is(value, op)
    return value if value.nil? || value.match(/"/)

    if op == "is"
      "\"#{value}\""
    else
      value
    end
  end

  def substitute_colons(value, _)
    return value if value.nil?

    value.gsub(/:/, " ")
  end

  private
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

      ops = params_field_ops(params)
      ops.each { |op, f|
        query_key, query_value = f
        # Fold the procedures onto the query value.
        params[query_key] = procedures.reduce(query_value) { |v, p| send(p, v, op) }
      }
      params
    end

    # Helper function that transforms the params in the typical
    # blacklight_params advanced search format into a list of tuples of the
    # form [[op, field])] where op is the operator and field is a key value
    # pair, [query_key, query_value].
    #
    # @param [ActionController::Parameters] params Set of search parameters.
    #
    # @return [Array] A transformed set of search parameters OR and empty set.
    def params_field_ops(params)
      begin
        fields = params.to_unsafe_h.compact.select { |k| k.match(/(^q$|^q_)/) }
        ops = params.to_unsafe_h.fetch("op_row", ["default"])
        ops.zip(fields)
      rescue
        []
      end
    end
end
