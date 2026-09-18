# frozen_string_literal: true

require "ostruct"

module LibrarySearch
  class ConstraintsComponent < Blacklight::ConstraintsComponent
    def initialize(**kwargs)
      kwargs[:facet_constraint_component] = kwargs.fetch(
        :facet_constraint_component, LibrarySearch::ConstraintComponent
      )
      kwargs[:query_constraint_component] = kwargs.fetch(
        :query_constraint_component, LibrarySearch::ConstraintLayoutComponent
      )
      kwargs[:start_over_component] = kwargs.fetch(
        :start_over_component, LibrarySearch::StartOverButtonComponent
      )
      super(**kwargs)
    end

    def query_constraints
      return legacy_query_constraints if advanced_query_constraints?

      super
    end

    def render?
      super || lc_range_constraint? || advanced_query_constraints?
    end

    def facet_constraints
      return super unless lc_range_constraint?

      updated_params = params.deep_dup
      updated_params["range"].delete("lc_classification")
      updated_params.delete("range") if updated_params["range"].empty?

      helpers.safe_join([
        super,
        render(LibrarySearch::ConstraintLayoutComponent.new(
                 label: helpers.facet_field_label("lc_classification"),
                 value: "#{lc_range['begin'].presence || '*'} to #{lc_range['end'].presence || '*'}",
                 remove_path: helpers.search_action_path(updated_params),
                 classes: "filter filter-lc_classification"
        ))
      ])
    end

    private

      def lc_range
        params.dig("range", "lc_classification") || {}
      end

      def lc_range_constraint?
        lc_range["begin"].present? || lc_range["end"].present?
      end

      def legacy_query_constraints
        return "".html_safe unless advanced_query_constraints?

        helpers.safe_join(guided_search_constraints, "\n")
      end

      def guided_search_constraints
        guided_search.map do |label, query, action|
          render(
            @query_constraint_component.new(
              label:,
              value: query,
              remove_path: helpers.search_action_path(remove_guided_keyword_query(action)),
              classes: "query"
            )
          )
        end
      end

      def advanced_query_constraints?
        return false unless params["search_field"] == helpers.blacklight_config.advanced_search[:url_key]

        params.any? do |key, value|
          key.match?(/\Aq_\d+\z/) && value.present?
        end || params["clause"].to_h.any? { |_, clause| clause["query"].present? }
      end

      def guided_search
        if params["clause"].present?
          return params["clause"].to_h.each_with_index.filter_map do |(_, clause), index|
            query = clause["query"]
            next if query.blank?

            field = helpers.blacklight_config.search_fields[clause["field"]]&.to_h || {}
            label = field[:label].to_s
            operator = index.positive? ? clause["op"] : nil
            operator = { "should" => "OR", "must_not" => "NOT", "must" => "AND" }[operator]

            [label, [operator, query].compact.join(" "), ["clause", index.to_s]]
          end
        end

        params.to_h.with_indifferent_access.select { |param| param.match?(/\Aq_\d+\z/) }
          .select { |key, _value| params[key].present? }
          .map do |key, _value|
            position = key.to_s[/_\d+$/]

            if position.nil?
              field_key = "search_field"
              operator_key = nil
            else
              position = position.delete("_").to_i
              field_key = "f_#{position}"
              operator_key = "op_#{position - 1}"
            end

            field = helpers.blacklight_config.search_fields[params[field_key]]&.to_h || {}
            label = field[:label].to_s
            query = if position == 1 || position.nil?
              params[key]
                    else
                      "#{params[operator_key]} #{params[key]}".strip
            end

            [label, query, [field_key, key, operator_key].compact]
          end
      end

      def remove_guided_keyword_query(fields)
        updated_params = Blacklight::SearchState.new(params.to_h, helpers.blacklight_config).to_h

        if fields.first == "clause"
          clauses = updated_params["clause"].to_h
          clauses.delete(fields.second)
          updated_params["clause"] = clauses.values.each_with_index.to_h { |clause, index| [index.to_s, clause] }
          updated_params.delete("q")
          updated_params.delete("processed")
          return updated_params
        end

        fields.each { |field| updated_params.delete(field) }
        updated_params.delete("q")
        updated_params.delete("processed")
        updated_params
      end

      def params
        @search_state.respond_to?(:params) ? @search_state.params.with_indifferent_access : {}.with_indifferent_access
      end

      def constraint_presenters
        return to_enum(:constraint_presenters) unless block_given?

        @search_state.filters.each do |facet|
          facet.each_value do |val|
            next if val.blank?

            presenter = constraint_presenter_for(facet.config, val, facet.key)
            next if omit_facet_constraint?(facet.key, presenter, val)

            decorate_presenter(presenter, facet.key, val)
            yield presenter
          end
        end
      end

      def decorate_presenter(presenter, field, value)
        case field.to_s
        when "lc_inner_facet"
          append_lc_parent(presenter)
        when "library_facet"
          hide_parent_if_child_selected(presenter, value)
        end
      end

      def append_lc_parent(presenter)
        parent_value = selected_values("lc_outer_facet").first
        return if parent_value.blank?

        return unless presenter.respond_to?(:parent=)

        presenter.parent = OpenStruct.new(field: "lc_outer_facet", value: parent_value)
        if presenter.respond_to?(:constraint_label_override=)
          presenter.constraint_label_override = "#{parent_value} | #{presenter.constraint_label}"
        end
      end

      def attach_library_parent(presenter, value)
        return if selected_values("library_facet").blank?

        parent_value = normalize_filter_value(value).to_s.split(" - ").first
        return if parent_value.blank?

        return unless presenter.respond_to?(:parent=)

        presenter.parent = OpenStruct.new(field: "library_facet", value: parent_value)
      end

      def hide_parent_if_child_selected(presenter, value)
        return if selected_values("location_facet").blank?

        parent_label = normalize_filter_value(value).to_s
        return if parent_label.blank?

        if selected_values("location_facet").any? { |loc| loc.match?(/#{Regexp.escape(parent_label)}/) }
          presenter.add_constraint_class("hidden") if presenter.respond_to?(:add_constraint_class)
        end
      end

      def omit_facet_constraint?(field, presenter = nil, value = nil)
        case field.to_s
        when "lc_facet"
          true
        when "lc_outer_facet"
          selected_values("lc_inner_facet").present?
        when "library_facet"
          location_selected_for?(value)
        else
          false
        end
      end

      def location_selected_for?(value)
        selected_values("location_facet").any? do |loc|
          loc.match?(/#{Regexp.escape(normalize_filter_value(value).to_s)}/)
        end
      end

      def selected_values(field)
        params = @search_state.respond_to?(:params) ? @search_state.params : @search_state
        return [] unless params

        values = params.dig(:f, field) || params.dig("f", field)
        Array.wrap(values).compact.map { |val| normalize_filter_value(val) }.reject(&:blank?)
      end

      def normalize_filter_value(value)
        return if value.nil?

        if value.respond_to?(:value)
          normalize_filter_value(value.value)
        elsif value.is_a?(Hash)
          normalize_filter_value(value[:value] || value["value"])
        else
          value.to_s
        end
      end

      def constraint_presenter_for(facet_config, facet_item, facet_field)
        if constraint_presenter_fields.include?(facet_field.to_s)
          ::FacetItemPresenter.new(facet_item, facet_config, helpers, facet_field)
        else
          helpers.facet_item_presenter(facet_config, facet_item, facet_field)
        end
      end

      def constraint_presenter_fields
        %w[library_facet location_facet lc_inner_facet]
      end

      def location_facet_configured?
        helpers.blacklight_config&.facet_fields&.key?("location_facet")
      end
  end
end
