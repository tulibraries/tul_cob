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

  def render_advanced_search_link
    return unless advanced_search_link_visible?

    link_to(
      t("blacklight.advanced_search.#{advanced_search_type}_link"),
      advanced_search_link_url,
      class: "advanced_search",
      data: { turbo: false }
    )
  end

  def advanced_search_link_visible?
    [
      search_catalog_path,
      search_journals_path,
      search_path,
      search_databases_path,
      everything_path,
      root_path
    ].any? { |path| current_page?(path) }
  end

  def advanced_search_link_url
    query = advanced_params(params)

    case advanced_search_type
    when :journals
      journals_advanced_path(query)
    when :articles
      articles_advanced_path(query)
    when :databases
      databases_advanced_path(query)
    else
      catalog_advanced_search_path(query)
    end
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

  def facet_value_checked?(field, value)
    search_state.filter(field).values.any? do |selected_value|
      selected_value = selected_value.value if selected_value.respond_to?(:value)
      selected_value.to_s == value.to_s
    end
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
    case advanced_search_type
    when :catalog
      search_catalog_path
    when :journals
      search_journals_path
    when :articles
      search_path
    when :databases
      search_databases_path
    else
      search_catalog_path
    end
  end

  def advanced_search_form_title
    case advanced_search_type
    when :journals
      t(:journals_advanced_search)
    when :articles
      t(:articles_advanced_search)
    when :databases
      t(:databases_advanced_search)
    else
      t(:catalog_advanced_search)
    end
  end

  def advanced_search_type
    case params[:controller].to_s
    when "journals"
      :journals
    when "primo_central"
      :articles
    when "databases"
      :databases
    when "catalog"
      :catalog
    else
      case
      when current_page?(catalog_advanced_search_path)
        :catalog
      when current_page?(journals_advanced_path)
        :journals
      when current_page?(articles_advanced_path)
        :articles
      when current_page?(databases_advanced_path)
        :databases
      else
        :catalog
      end
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
