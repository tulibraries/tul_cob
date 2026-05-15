# frozen_string_literal: true

module AdvancedHelper
  def catalog_advanced_search_path(query = nil)
    path = "/catalog/advanced"
    query.present? ? "#{path}?#{query.to_query}" : path
  end

  def journals_advanced_path(query = nil)
    path = "/journals/advanced"
    query.present? ? "#{path}?#{query.to_query}" : path
  end

  def articles_advanced_path(query = nil)
    path = "/articles/advanced"
    query.present? ? "#{path}?#{query.to_query}" : path
  end

  def databases_advanced_path(query = nil)
    path = "/databases/advanced"
    query.present? ? "#{path}?#{query.to_query}" : path
  end

  def sort_fields
    active_sort_fields.values.map { |field_config|
      [sort_field_label(field_config.key), field_config.key]
    }
  end

  def label_tag_default_for(key)
    clause_key = clause_value_for_legacy_key(key)

    unless params[key] || clause_key.present?
      if ("f_1" == key)
        return params["search_field"]
      elsif ("q_1" == key)
        return params["q"]
      end
    end

    if !params[key].blank?
      return params[key]
    elsif clause_key.present?
      return clause_key
    elsif params["search_field"] == key
      return params["q"]
    else
      return nil
    end
  end

  def advanced_key_value
    key_value = []
    search_fields_for_advanced_search.each do |field|
      key_value << [field[1][:label], field[0]]
    end
    key_value
  end

  # Get default value for operator[] field in advanced_search form.
  def operator_default(count)
    clause_match = params.dig("clause", (count - 1).to_s, "match") || params.dig(:clause, (count - 1).to_s, :match)

    if clause_match.present?
      clause_match
    elsif !params["operator"]
      "contains"
    else
      params["operator"]["q_#{count}"]
    end
  end

  def search_fields_for_advanced_search
    search_fields_for_advanced_search ||= begin
      hash = blacklight_config.search_fields.class.new
      blacklight_config.search_fields.each_pair do |key, value|
        hash[key] = value unless value.include_in_advanced_search == false
      end
      hash
    end
  end

  def booleans(op_num, op)
    clause_index = op_num.to_s.delete_prefix("op_").to_i
    clause_op = params.dig("clause", clause_index.to_s, "op") || params.dig(:clause, clause_index.to_s, :op)

    if clause_op.present?
      mapped_op = case clause_op
                  when "should" then "OR"
                  when "must_not" then "NOT"
                  else "AND"
                  end
      mapped_op == op
    elsif params[op_num]
      params[op_num] == op
    else
      op == "AND"
    end
  end

  def advanced_search_config
    blacklight_config.fetch(:advanced_search, {})
  end

  def clause_value_for_legacy_key(key)
    match = key.to_s.match(/\A([fq])_(\d+)\z/)
    return unless match

    type, index = match.captures
    clause = params.dig("clause", (index.to_i - 1).to_s) || params.dig(:clause, (index.to_i - 1).to_s)
    return unless clause

    if type == "f"
      clause["field"] || clause[:field]
    else
      clause["query"] || clause[:query]
    end
  end

  def facet_field_names
    Array(advanced_search_config.dig(:form_solr_parameters, "facet.field") || advanced_search_config.dig("form_solr_parameters", "facet.field")).map(&:to_s)
  end

  def advanced_filters_present?
    facet_field_names.any? do |field|
      next false if field == "lc_facet"

      @response&.aggregations&.[](field).present?
    end ||
      @response&.aggregations&.[]("pub_date_sort").present? ||
      params.dig("range", "pub_date_sort").present? ||
      params.dig("range", "lc_classification").present?
  end

  def advanced_params(my_params)
    my_params.except(:controller, :action)
      .select { |k, v|
        # Sometimes is_advanced_search? does not return true|false answer.
        # And, sometimes is_advanced_search? is not available at all.
        if begin !(is_advanced_search? == true) rescue false end
          !k.match?(/^(q|op|f)_/)
        else
          true
        end
      }.to_h
  end

  def basic_search_path
    if current_page? catalog_advanced_search_path
      search_catalog_path
    elsif current_page? journals_advanced_path
      search_journals_path
    elsif current_page? articles_advanced_path
      search_path
    elsif current_page? databases_advanced_path
      search_databases_path
    else
      search_catalog_path
    end
  end

  def advanced_search_form_title
    if current_page? catalog_advanced_search_path
      t(:catalog_advanced_search)
    elsif current_page? journals_advanced_path
      t(:journals_advanced_search)
    elsif current_page? articles_advanced_path
      t(:articles_advanced_search)
    elsif current_page? databases_advanced_path
      t(:databases_advanced_search)
    else
      t(:catalog_advanced_search)
    end
  end

  def render_pub_date_range
    if blacklight_config.facet_fields["pub_date_sort"]
      render "advanced/pub_date_sort_facet"
    end
  end

  def render_classification_range
    if blacklight_config.facet_fields["lc_facet"]
      render "advanced/classification_range"
    end
  end
end

module BlacklightAdvancedSearch
  class QueryParser
    include AdvancedHelper
    include Blacklight::PrimoCentral::SolrAdaptor

    def clauses
      @clauses ||= if @params[:clause].present?
                     @params[:clause].to_h.sort_by { |key, _value| key.to_i }.map do |_key, clause|
                       clause.with_indifferent_access
                     end.select { |clause| clause[:query].present? }
                   else
                     legacy_clauses
                   end
    end

    def keyword_op
      keyword_queries
      @keyword_op || []
    end

    def keyword_queries
      unless @keyword_queries
        @keyword_queries = {}
        @keyword_op = []

        advanced_url_key = CatalogController.blacklight_config.advanced_search[:url_key] || "advanced"
        return @keyword_queries unless @params[:search_field] == advanced_url_key

        clauses.each_with_index do |clause, index|
          field = clause[:field]
          next if field.blank?

          query = odd_quotes(clause[:query])
          op = normalize_legacy_op(clause[:op])
          field_already_seen = @keyword_queries.key?(field)

          if field_already_seen
            merge_op = op.presence || "AND"
            @keyword_queries[field] = if merge_op == "NOT"
                                        "(#{@keyword_queries[field]}) NOT (#{query})"
                                      else
                                        "(#{@keyword_queries[field]}) #{merge_op} (#{query})"
                                      end
          elsif op == "NOT" && index.positive?
            @keyword_queries[field] = "NOT #{query}"
          else
            @keyword_queries[field] = query
          end

          if index.positive? && op.present? && op != "NOT" && !field_already_seen
            @keyword_op << op
          end
        end
      end
      @keyword_queries
    end

    def solr_query(config)
      queries = []
      ops = keyword_op.dup

      keyword_queries.each do |field, query|
        field = primo_to_solr_search(field)
        queries << ParsingNesting::Tree.parse(query, config.advanced_search[:query_parser]).to_query(local_param_hash(field, config))
        queries << ops.shift
      end

      queries.compact.join(" ")
    end

    def local_param_hash(key, config)
      field_def = config.search_fields[key] || {}

      (field_def[:solr_adv_parameters] || field_def[:solr_parameters] || {}).merge(field_def[:solr_local_parameters] || {})
    end

    private

      def legacy_clauses
        (1..3).map do |index|
          query = @params["q_#{index}"]
          next if query.blank?

          {
            field: @params["f_#{index}"],
            query:,
            match: @params.dig("operator", "q_#{index}"),
            op: index == 1 ? nil : @params["op_#{index - 1}"]
          }.with_indifferent_access
        end.compact
      end

      def normalize_legacy_op(op)
        case op
        when "must" then "AND"
        when "should" then "OR"
        when "must_not" then "NOT"
        else op
        end
      end

      # Remove stray quotation mark if there is an odd number
      # @param query the query
      # @return the query with an even number of quotation marks
      def odd_quotes(query)
        if query&.count('"')&.odd?
          query.sub(/"/, "")
        else
          query
        end
      end
  end
end

module BlacklightAdvancedSearch
  module ParsingNestingParser
    def process_query(_params, config)
      queries = []
      ops = keyword_op
      keyword_queries.each do |field, query|
        field = primo_to_solr_search(field)
        if field == "title_starts_with"
          queries << %(_query_:"{!lucene df=title_sort}#{query}")
        else
          queries << ParsingNesting::Tree.parse(query, config.advanced_search[:query_parser]).to_query(local_param_hash(field, config))
        end
        queries << ops.shift
      end
      queries.join(" ")
    end
  end
end

module BlacklightAdvancedSearch
  module CatalogHelperOverride
    def remove_guided_keyword_query(fields, my_params = params)
      my_params = Blacklight::SearchState.new(my_params.to_h, blacklight_config).to_h
      fields.each do |guided_field|
        my_params.delete(guided_field)
      end
      my_params
    end
  end
end

module BlacklightAdvancedSearch
  module RenderConstraintsOverride
    # This overrides a method from Blacklight 7 that will be removed from Blacklight 8.
    # Overrides Blacklight::RenderConstraintsHelperBehavior#render_constraints_query.
    # We need this in order to render multiple clearable buttons on advanced searches.
    def render_constraints_query(my_params = params)
      # Short circuit if this is not an advanced query.
      if advanced_query.nil? || advanced_query.keyword_queries.empty?
        return super(my_params)
      end

      buttons = guided_search(my_params).map { |s|
        label, query, action = s

        render_constraint_element(
          label, query,
          remove: search_action_path(remove_guided_keyword_query(action, my_params))
        )
      }.flatten
      safe_join(buttons, "\n")
    end

    def guided_search(my_params = params)
      my_params.to_h
        .with_indifferent_access.select { |p| p.match(/^q/) }
        .select { |q, v| ! my_params.to_h[q].blank? }
        .map { |q, v|
          position = q.to_s.scan(/_\d+$/)[0]

          if position.nil?
            f = "search_field"
          else
            position = position.gsub("_", "").to_i
            f = "f_#{position}"
            # position -1 gets us the first op
            op = "op_#{position - 1}"
          end

          field = blacklight_config.search_fields[my_params.to_h[f]].to_h
          label = field[:label].to_s
          if position == 1
            query = my_params.to_h[q]
          else
            query = my_params.to_h[op].to_s + " " + my_params.to_h[q]
          end
          [label, query, [f, q, op]]
        }
    end
  end
end
