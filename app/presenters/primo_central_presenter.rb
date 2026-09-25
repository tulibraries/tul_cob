# frozen_string_literal: true

class PrimoCentralPresenter < IndexPresenter
  def label(field, opts = {})
    with_subtitle(document[:title]).html_safe
  end

  def with_subtitle(title)
    return title unless document.key?(:subtitle) && document[:subtitle]

    "#{title}: #{document[:subtitle]}"
  end

  def purchase_order_button
    # There is no purchase of Primo docs for now.
  end
end
