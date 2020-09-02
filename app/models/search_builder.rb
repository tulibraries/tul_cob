# frozen_string_literal: true

class SearchBuilder < Blacklight::SearchBuilder
  include Blacklight::Solr::SearchBuilderBehavior
  include BlacklightAdvancedSearch::AdvancedSearchBuilder
  include BlacklightRangeLimit::RangeLimitBuilder
  include BentoSearchBuilderBehavior

  BEGINS_WITH_TAG = "matchbeginswith"
  ENDS_WITH_TAG = "matchendswith"

  self.default_processor_chain +=
    %i[ add_advanced_parse_q_to_solr
        add_advanced_search_to_solr
        spellcheck
        filter_suppressed
        limit_facets
        sorting_preferences ]

  if ENV["SOLR_SEARCH_TWEAK_ENABLE"] == "on"
    self.default_processor_chain += %i[ tweak_query ]
  end

  def filter_purchase_order(solr_params)
    # The negative query will work even when items are not indexed.
    # We can refactor to use a positive query once indexing occurs.
    solr_params["fq"] = solr_params["fq"].push("-purchase_order:true")
  end

  # Remove this once we update and use new tul_cob-catalog-solr config
  def filter_suppressed(solr_params)
    if !solr_params["fq"].include?("-suppress_items_b:true")
      solr_params["fq"] = solr_params["fq"].push("-suppress_items_b:true")
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
    end
  end

  def sorting_preferences(solr_parameters)
    solr_parameters["f.lc_outer_facet.facet.sort"] = "index"
    solr_parameters["f.lc_inner_facet.facet.sort"] = "index"
  end

  def tweak_query(solr_parameters)
    solr_parameters.merge!(blacklight_params.select { |name, value| name.match?(/(qf$|pf$)/) })
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
    [ :process_begins_with, :process_is, :substitute_colons ]
  end

  def process_begins_with(value, op)
    if op == "begins_with"
      process_is("#{BEGINS_WITH_TAG} " + value, "is") rescue value
    else
      value
    end
  end

  def process_is(value, op)
    return if value.nil?
    return value if value.match(/"/) rescue true
    if op == "is"
      "\"#{value}\""
    else
      value
    end
  end

  def substitute_colons(value, _)
    value.gsub(/:/, " ") rescue value
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

      # Do not process non query values
      ops = params.fetch("operator", "q" => "default")
        .select { |key, value| key.match?(/^q/) }

      # query_key are like "q_1", "q_2"..., etc.
      # op is like "contains", "begins_with"..., etc.
      ops.each { |query_key, op|
        query_value = params[query_key]

        # Fold the procedures onto the query value.
        params[query_key] = procedures.reduce(query_value) { |v, p| send(p, v, op) }
      }
      params
    end
end
