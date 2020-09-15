# frozen_string_literal: true

class FacetItemPivotComponent < Blacklight::FacetItemPivotComponent
  with_collection_parameter :facet_item

  def uncollapse?
    return view_context.facet_field_in_params?(@facet_item.items[0].field) &&
           params["f"][@facet_item.items[0].field] &&
           params["f"][@facet_item.items[0].field].include?(@facet_item.items[0].value)
  end

  def call
    facet = Blacklight::FacetItemComponent.new(facet_item: @facet_item, wrapping_element: nil, suppress_link: @suppress_link)

    id = "h-#{self.class.mint_id}" if @collapsing && has_items?

    content_tag @wrapping_element, role: "treeitem" do
      concat facet_toggle_button(id) if has_items? && @collapsing
      concat content_tag("span", render_component(facet), class: "facet-values #{'facet-leaf-node' if has_items? && @collapsing}", id: id && "#{id}_label")

      if has_items?
        concat(content_tag("ul", class: "pivot-facet list-unstyled #{'collapse' if @collapsing} #{'show' if uncollapse?}", id: id, role: "group") do
                 render_component(
                   self.class.with_collection(
                     @facet_item.items.map { |i| facet_item_presenter(i) }
                   )
                 )
               end)
      end
    end
  end

  def facet_toggle_button(id)
    content_tag "button", class: "btn facet-toggle-handle #{'collapsed' unless uncollapse?}",
                data: { toggle: "collapse", target: "##{id}" },
                aria: { expanded: uncollapse?, controls: id, describedby: "#{id}_label" } do
      concat toggle_icon(:show)
      concat toggle_icon(:hide)
    end
  end
end
