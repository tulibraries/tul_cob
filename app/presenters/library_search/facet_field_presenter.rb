# frozen_string_literal: true

module LibrarySearch
  class FacetFieldPresenter < Blacklight::FacetFieldPresenter
    def active?
      return true if pivot_child_selected?

      super
    end

    def paginator
      return super unless facet_field.pivot

      @paginator ||= blacklight_config.facet_paginator_class.new(
        alphabetical_pivot_items,
        sort: display_facet.sort,
        offset: display_facet.offset,
        prefix: display_facet.prefix,
        limit: facet_limit
      )
    end

    private

      def alphabetical_pivot_items
        display_facet.items.sort_by { |item| item.value.to_s.downcase }
      end

      def pivot_child_selected?
        child_field = facet_field.pivot&.last
        return false unless child_field

        Array(search_state.params.dig(:f, child_field)).any?(&:present?)
      end
  end
end
