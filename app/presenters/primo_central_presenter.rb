class PrimoCentralPresenter < Blacklight::IndexPresenter


  def label(field, opts={})
    with_subtitle(document[:title]).html_safe
  end

  def with_subtitle(title)
    title << ": #{document[:subtitle]}" if (document.key? :subtitle and document[:subtitle])
    title
  end

end
