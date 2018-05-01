# frozen_string_literal: true

module AdvancedHelper
  include BlacklightAdvancedSearch::AdvancedHelperBehavior

  def label_tag_default_for(key)
    unless params[key]
      if ("f_1" == key)
        return params["search_field"]
      elsif ("q_1" == key)
        return params["q"]
      end
    end

    if !params[key].blank?
      return params[key]
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

  # Get default value for op_row[] field in advanced_search form.
  def op_row_default(count)
    if !params["op_row"]
      "contains"
    else
      # Always select from last rows count of total values in op_row[]
      # @see BL-334
      rows = params.select { |k| k.match(/^q_/) }
      count_rows = rows.to_h.count
      params["op_row"][-count_rows + count - 1]
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
    if params[op_num]
      params[op_num] == op
    else
      op == "AND"
    end
  end

  def advanced_search_config
    blacklight_config.fetch(:advanced_search, {})
  end
end

module BlacklightAdvancedSearch
  class QueryParser
    include AdvancedHelper

    def keyword_op
      # NOTs get added to the query. Only AND/OR are operations
      @keyword_op = []
      unless @params[:q_1].blank? || @params[:q_2].blank? || @params[:op_1] == "NOT"
        @keyword_op << @params[:op_1] if @params[:f_1] != @params[:f_2]
      end
      unless @params[:q_3].blank? || @params[:op_2] == "NOT" || (@params[:q_1].blank? && @params[:q_2].blank?)
        @keyword_op << @params[:op_2] unless [@params[:f_1], @params[:f_2]].include?(@params[:f_3]) && ((@params[:f_1] == @params[:f_3] && !@params[:q_1].blank?) || (@params[:f_2] == @params[:f_3] && !@params[:q_2].blank?))
      end
      @keyword_op
    end

    def keyword_queries
      unless @keyword_queries
        @keyword_queries = {}

        return @keyword_queries unless @params[:search_field] == ::AdvancedController.blacklight_config.advanced_search[:url_key]

        q1 = @params[:q_1]
        q2 = @params[:q_2]
        q3 = @params[:q_3]

        been_combined = false
        @keyword_queries[@params[:f_1]] = q1 unless @params[:q_1].blank?
        unless @params[:q_2].blank?
          if @keyword_queries.key?(@params[:f_2])
            @keyword_queries[@params[:f_2]] = "(#{@keyword_queries[@params[:f_2]]}) " + @params[:op_1] + " (#{q2})"
            been_combined = true
          elsif @params[:op_1] == "NOT"
            @keyword_queries[@params[:f_2]] = "NOT " + q2
          else
            @keyword_queries[@params[:f_2]] = q2
          end
        end
        unless @params[:q_3].blank?
          if @keyword_queries.key?(@params[:f_3])
            @keyword_queries[@params[:f_3]] = "(#{@keyword_queries[@params[:f_3]]})" unless been_combined
            @keyword_queries[@params[:f_3]] = "#{@keyword_queries[@params[:f_3]]} " + @params[:op_2] + " (#{q3})"
          elsif @params[:op_2] == "NOT"
            @keyword_queries[@params[:f_3]] = "NOT " + q3
          else
            @keyword_queries[@params[:f_3]] = q3
          end
        end
      end
      @keyword_queries
    end
  end
end

module BlacklightAdvancedSearch
  module ParsingNestingParser
    def process_query(_params, config)
      queries = []
      ops = keyword_op
      keyword_queries.each do |field, query|
        queries << ParsingNesting::Tree.parse(query, config.advanced_search[:query_parser]).to_query(local_param_hash(field, config))
        queries << ops.shift
      end
      queries.join(" ")
    end
  end
end

module BlacklightAdvancedSearch
  module CatalogHelperOverride
    def remove_guided_keyword_query(fields, my_params = params)
      my_params = Blacklight::SearchState.new(my_params, blacklight_config).to_h
      fields.each do |guided_field|
        my_params.delete(guided_field)
      end
      my_params
    end
  end
end

module BlacklightAdvancedSearch
  module RenderConstraintsOverride
    # Overrides Blacklight::RenderConstraintsHelperBehavior#render_constraints_query
    # We need this in order to render multiple clearable buttons on advanced searches.

    def render_constraints_query(my_params = params)
      buttons = guided_search.map { |s|
        label, query, action = s

        render_constraint_element(
          label, query,
          remove: search_action_path(remove_guided_keyword_query(action, my_params))
        )
      }.flatten

      safe_join(buttons, "\n")
    end

    def guided_search(my_params = params)
      my_params.select { |p| p.match(/^q/) }
        .to_unsafe_h.with_indifferent_access
        .select { |q, v| ! my_params[q].blank? }
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

        field = blacklight_config.search_fields[my_params[f]].to_h
        label = field[:label].to_s
        if position == 1
          query = my_params[q]
        else
          query = my_params[op].to_s + " " + my_params[q]
        end
        [label, query, [f, q, op]]
      }
    end
  end
end
