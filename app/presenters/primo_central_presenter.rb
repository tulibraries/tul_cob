# frozen_string_literal: true

class PrimoCentralPresenter < Blacklight::IndexPresenter
  def label(field, opts = {})
    with_subtitle(document[:title]).html_safe
  end

  def with_subtitle(title)
    title << ": #{document[:subtitle]}" if (document.key?(:subtitle) && document[:subtitle])
    title
  end

  def purchase_order_button
    # There is no purchase of Primo docs for now.
  end
end
