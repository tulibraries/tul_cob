module AdvancedHelper
  include BlacklightAdvancedSearch::AdvancedHelperBehavior

  def advanced_key_value
    key_value = []
    search_fields_for_advanced_search.each do |field|
      key_value << [field[1][:label], field[0]]
    end
    key_value
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
      op == 'AND'
    end
  end
end

module BlacklightAdvancedSearch
  class QueryParser
    include AdvancedHelper

    def keyword_op
      # NOTs get added to the query. Only AND/OR are operations
      @keyword_op = []
      unless @params[:q1].blank? || @params[:q2].blank? || @params[:op2] == 'NOT'
        @keyword_op << @params[:op2] if @params[:f1] != @params[:f2]
      end
      unless @params[:q3].blank? || @params[:op3] == 'NOT' || (@params[:q1].blank? && @params[:q2].blank?)
        @keyword_op << @params[:op3] unless [@params[:f1], @params[:f2]].include?(@params[:f3]) && ((@params[:f1] == @params[:f3] && !@params[:q1].blank?) || (@params[:f2] == @params[:f3] && !@params[:q2].blank?))
      end
      @keyword_op
    end

    def keyword_queries
        unless @keyword_queries
          @keyword_queries = {}

          return @keyword_queries unless @params[:search_field] == ::AdvancedController.blacklight_config.advanced_search[:url_key]

          q1 = @params[:q1]
          q2 = @params[:q2]
          q3 = @params[:q3]

          been_combined = false
          @keyword_queries[@params[:f1]] = q1 unless @params[:q1].blank?
          unless @params[:q2].blank?
            if @keyword_queries.key?(@params[:f2])
              @keyword_queries[@params[:f2]] = "(#{@keyword_queries[@params[:f2]]}) " + @params[:op2] + " (#{q2})"
              been_combined = true
            elsif @params[:op2] == 'NOT'
              @keyword_queries[@params[:f2]] = 'NOT ' + q2
            else
              @keyword_queries[@params[:f2]] = q2
            end
          end
          unless @params[:q3].blank?
            if @keyword_queries.key?(@params[:f3])
              @keyword_queries[@params[:f3]] = "(#{@keyword_queries[@params[:f3]]})" unless been_combined
              @keyword_queries[@params[:f3]] = "#{@keyword_queries[@params[:f3]]} " + @params[:op3] + " (#{q3})"
            elsif @params[:op3] == 'NOT'
              @keyword_queries[@params[:f3]] = 'NOT ' + q3
            else
              @keyword_queries[@params[:f3]] = q3
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
      queries.join(' ')
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
          remove: search_catalog_path(remove_guided_keyword_query(action, my_params))
        )
      }.flatten

      safe_join(buttons, "\n")
    end

    def guided_search(my_params = params)
      my_params.select { |p| p.match(/^q/) }
        .to_unsafe_h.with_indifferent_access
        .select { |q, v| ! my_params[q].blank? }
        .map { |q, v|

        position = q.to_s.scan(/\d+$/)[0]
        f = "f#{position}".to_sym
        op = "op#{position}".to_sym
        label = search_field_def_for_key(my_params[f])[:label]
        query = my_params[op].to_s + " " + my_params[q]
        [label, query, [f, q, op]]
      }
    end
  end
end
