# app/components/facet_item_pivot_component.rb
# frozen_string_literal: true

class FacetItemPivotComponent < Blacklight::FacetItemPivotComponent
  with_collection_parameter :facet_item

  def call
    facet = LibrarySearch::FacetItemComponent.new(
      facet_item: @facet_item,
      wrapping_element: nil,
      suppress_link: @suppress_link
    )

    id = "h-#{self.class.mint_id}" if @collapsing && has_items?

    li_content = ActiveSupport::SafeBuffer.new

    li_content.safe_concat spacer_cell unless nested?

    li_content.safe_concat(
      content_tag(:div, class: content_cell_classes) do
        content = ActiveSupport::SafeBuffer.new

        content.safe_concat facet_toggle_button(id) if has_items? && @collapsing

        content.safe_concat(
          content_tag(
            :span,
            render(facet),
            class: "facet-values #{'facet-leaf-node' if has_items? && @collapsing}",
            id: id && "#{id}_label"
          )
        )

        if has_items?
          content.safe_concat(
            content_tag(
              :ul,
              class: nested_list_classes,
              id: id,
              role: "group"
            ) do
              render(
                self.class.with_collection(
                  @facet_item.facet_item_presenters.to_a,
                  wrapping_element: :li,
                  suppress_link: @suppress_link,
                  collapsing: @collapsing
                )
              )
            end
          )
        end

        content
      end
    )

    li_content.safe_concat spacer_cell unless nested?

    li_tag =
      if @wrapping_element.present?
        content_tag(@wrapping_element, li_content, role: "treeitem")
      else
        li_content
      end

    return li_tag if nested?

    safe_join([li_tag, horizontal_spacer])
  end

  private

    def nested?
      # Child pivot items are location_facet rows.
      # Parent pivot items are library_facet rows.
      @facet_item.respond_to?(:nested?) ? @facet_item.nested? : false
    end

    def content_cell_classes
      [
        "pivot-facet-content-cell",
        nested? ? "pivot-facet-inner" : "pivot-facet-outer"
      ].join(" ")
    end

    def nested_list_classes
      [
        "pivot-facet",
        "list-unstyled",
        ("collapse" if @collapsing),
        ("show" if uncollapse?)
      ].compact.join(" ")
    end

    def spacer_cell
      content_tag(:span, "", class: "pivot-facet-spacer-cell")
    end

    def horizontal_spacer
      content_tag(:span, class: "pivot-facet-spacer-row") do
        safe_join(
          3.times.map { content_tag(:span, "", class: "pivot-facet-spacer-row-inner") }
        )
      end
    end

    def facet_toggle_button(id)
      content_tag(
        :button,
        type: "button",
        class: [
          "btn",
          "pivot-top-level-expand",
          "facet-toggle-handle",
          ("collapsed" unless uncollapse?)
        ].compact.join(" "),
        data: {
          "bs-toggle": "collapse",
          "bs-target": "##{id}"
        },
        aria: {
          expanded: uncollapse?,
          controls: id,
          describedby: "#{id}_label"
        }
      ) do
        safe_join([toggle_icon(:show), toggle_icon(:hide)])
      end
    end

    def uncollapse?
      @facet_item.respond_to?(:has_selected_child?) && @facet_item.has_selected_child?
    end
end
