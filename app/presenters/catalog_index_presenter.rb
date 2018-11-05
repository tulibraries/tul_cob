# frozen_string_literal: true

class CatalogIndexPresenter < Blacklight::IndexPresenter
  def purchase_order_button
    path = view_context.purchase_order_path(id: @document.id)

    link = view_context.link_to "Request Rapid Access", path, class: "btn btn-sm btn-danger", title: "Open a modal form to request a purchase for this item.", target: "_blank", id: "purchase_order_button-#{@document.id}", data: { "ajax-modal": "trigger" }
    view_context.content_tag :div, link, class: "availability"
  end
end
