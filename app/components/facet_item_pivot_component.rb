# frozen_string_literal: true

class FacetItemPivotComponent < Blacklight::FacetItemPivotComponent
  with_collection_parameter :facet_item

  # We want to "uncollapse" when the search state already includes a subfacet,
  # so that we can show the selected facet in the side panel
  def uncollapse?
    return false unless params["f"]
    if @facet_item.facet_item.field == "library_facet"
      return @facet_item.items.any? { |i|
        params["f"][i.field] && params["f"][i.field].include?(i.value) && i.value.match?(/#{@facet_item.facet_item.value}/)
      }
    end
    return false unless @facet_item.items.size == 1 && params["f"][@facet_item.items[0].field]
    return params["f"][@facet_item.items[0].field].include?(@facet_item.items[0].value)
  end

  def call
    facet = FacetItemComponent.new(facet_item: @facet_item, wrapping_element: nil, suppress_link: @suppress_link)

    id = "h-#{self.class.mint_id}" if @collapsing && has_items?

    li_tag = content_tag @wrapping_element, role: "treeitem" do
      concat content_tag(:span, "", class: "pivot-facet-spacer-cell") unless @facet_item.nested?
      concat(content_tag(:div, class: "pivot-facet-content-cell") do
        concat facet_toggle_button(id) if has_items? && @collapsing
        concat content_tag("span", render_component(facet), class: "facet-values #{'facet-leaf-node' if has_items? && @collapsing}", id: id && "#{id}_label")

        if has_items?
          concat(content_tag("ul", class: "pivot-facet list-unstyled #{'collapse' if (@collapsing && !uncollapse?)} #{'show' if uncollapse?}", id: id, role: "group") do
                   render_component(
                     self.class.with_collection(
                       @facet_item.items.map { |i| facet_item_presenter(i, @facet_item.facet_item) }
                     )
                   )
                 end)
        end
      end)
      concat content_tag(:span, "", class: "pivot-facet-spacer-cell") unless @facet_item.nested?
    end

    unless @facet_item.nested?
      horizontal_spacer = content_tag(:span, class: "pivot-facet-spacer-row") do
        3.times { concat content_tag(:span, "", class: "pivot-facet-spacer-row-inner") }
      end
      li_tag += horizontal_spacer
    end

    return li_tag
  end

  def facet_toggle_button(id)
    content_tag "button", class: "btn facet-toggle-handle #{'collapsed' unless uncollapse?}",
                data: { toggle: "collapse", target: "##{id}" },
                aria: { expanded: uncollapse?, controls: id, describedby: "#{id}_label" } do
      concat toggle_icon(:show)
      concat toggle_icon(:hide)
    end
  end

  def facet_item_presenter(facet_item, parent_facet_item = nil)
    presenter = FacetItemPresenter.new(facet_item, @facet_item.facet_config, @view_context, @facet_item.facet_field, @facet_item.search_state)
    presenter.parent = parent_facet_item if parent_facet_item
    presenter
  end
end
