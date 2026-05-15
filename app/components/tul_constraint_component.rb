# frozen_string_literal: true

class TulConstraintComponent < Blacklight::ConstraintComponent
  def initialize(facet_item_presenter:, classes: "filter", layout: TulConstraintLayoutComponent)
    presenter_classes = Array(classes)
    if facet_item_presenter.respond_to?(:constraint_classes)
      presenter_classes += Array(facet_item_presenter.constraint_classes)
    end

    super(facet_item_presenter: facet_item_presenter,
          classes: presenter_classes,
          layout: layout)
  end
end
