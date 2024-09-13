# frozen_string_literal: true

module PurchaseOrderHelper
  def render_purchase_order_availability(presenter)
    doc = presenter.document
    return unless doc.purchase_order?


    field = presenter.send(:fields)["purchase_order_availability"]

    if field.with_panel
      rows = [ t("purchase_order.purchase_order_allowed") ]
      render partial: "availability_panel", locals: { label: field.label, rows: }

    elsif current_user && !current_user.can_purchase_order?
      content_tag :div, t("purchase_order.purchase_order_allowed"), class: "availability"
    else
      render_purchase_order_button(document: doc, config: field)
    end
  end

  def render_purchase_order_button(args)
    return unless args[:document].purchase_order?

    doc = args[:document]
    with_po_link = args.dig(:config, :with_po_link)

    if !current_user
      link = with_po_link ? render_purchase_order_show_link(args) : ""
      render partial: "purchase_order_anonymous_button", locals: { link:, document: doc }
    elsif current_user.can_purchase_order?
      label = content_tag :span, "Request Rapid Access", class: "avail-label"
      path = purchase_order_path(id: doc.id)
      link = link_to label, path, class: "btn purchase-order", title: "Open a modal form to request a purchase for this item.", target: "_blank", id: "purchase_order_button-#{doc.id}", data: { "blacklight-modal": "trigger" }
      content_tag :div, link, class: "requests-container mb-2 ms-0"
    end
  end

  def render_purchase_order_show_link(args = { document: @document })
    return unless args[:document].purchase_order?

    if !current_user
      id = args[:document].id
      link_to("Log in to access request form", doc_redirect_url(id), data: { "blacklight-modal": "trigger" })
    elsif current_user.can_purchase_order?
      render_purchase_order_button(args)
    end
  end
end
