# frozen_string_literal: true

class FacetItemPivotComponent < Blacklight::FacetItemPivotComponent
  with_collection_parameter :facet_item

  # We want to "uncollapse" when the search state already includes a subfacet,
  # so that we can show the selected facet in the side panel
  def uncollapse?
    @facet_item.has_selected_child?
  end

  def call
    facet = FacetItemComponent.new(facet_item: @facet_item, wrapping_element: nil, suppress_link: @suppress_link)

    id = "h-#{self.class.mint_id}" if @collapsing && has_items?

    li_content = ActiveSupport::SafeBuffer.new
    li_content.safe_concat content_tag(:span, "", class: "pivot-facet-spacer-cell") unless @facet_item.nested?
    li_content.safe_concat(
      content_tag(:div, class: "pivot-facet-content-cell #{@facet_item.nested? ? 'pivot-facet-inner' : 'pivot-facet-outer'}") do
        content = ActiveSupport::SafeBuffer.new
        content.safe_concat facet_toggle_button(id) if has_items? && @collapsing
        content.safe_concat content_tag("span", render(facet), class: "facet-values #{'facet-leaf-node' if has_items? && @collapsing}", id: id && "#{id}_label")

        if has_items?
          content.safe_concat(
            content_tag("ul", class: "pivot-facet list-unstyled #{'collapse' if (@collapsing && !uncollapse?)} #{'show' if uncollapse?}", id:, role: "group") do
              render(
                self.class.with_collection(
                  child_items.map { |i| facet_item_presenter(i, @facet_item.facet_item) }
                )
              )
            end
          )
        end

        content
      end
    )
    li_content.safe_concat content_tag(:span, "", class: "pivot-facet-spacer-cell") unless @facet_item.nested?

    li_tag = if @wrapping_element.present?
      content_tag @wrapping_element, li_content, role: "treeitem"
             else
               li_content
    end

    return li_tag if @facet_item.nested?

    horizontal_spacer = content_tag(:span, class: "pivot-facet-spacer-row") do
      row = ActiveSupport::SafeBuffer.new
      3.times { row.safe_concat content_tag(:span, "", class: "pivot-facet-spacer-row-inner") }
      row
    end

    output = ActiveSupport::SafeBuffer.new
    output.safe_concat(li_tag)
    output.safe_concat(horizontal_spacer)
    output
  end

  def facet_toggle_button(id)
    content_tag "button", class: "btn pivot-top-level-expand facet-toggle-handle #{'collapsed' unless uncollapse?}",
                "data": { "bs-toggle": "collapse", "bs-target": "##{id}" },
                aria: { expanded: uncollapse?, controls: id, describedby: "#{id}_label" } do
      concat toggle_icon(:show)
      concat toggle_icon(:hide)
    end
  end

  def child_items
    return [] unless @facet_item.respond_to?(:items)

    @facet_item.items || []
  end

  def has_items?
    child_items.any?
  end

  def facet_item_presenter(facet_item, parent_facet_item = nil)
    presenter_context = @view_context.respond_to?(:helpers) ? @view_context.helpers : @view_context
    presenter = FacetItemPresenter.new(facet_item, @facet_item.facet_config, presenter_context, @facet_item.facet_field, @facet_item.search_state)
    presenter.parent = parent_facet_item if parent_facet_item
    presenter
  end
end
