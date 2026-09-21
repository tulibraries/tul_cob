# frozen_string_literal: true

module LibrarySearch
  class ConstraintComponent < Blacklight::ConstraintComponent
    def initialize(facet_item_presenter:, classes: "filter", layout: LibrarySearch::ConstraintLayoutComponent)
      presenter_classes = Array(classes)
      if facet_item_presenter.respond_to?(:constraint_classes)
        presenter_classes += Array(facet_item_presenter.constraint_classes)
      end

      super(facet_item_presenter: facet_item_presenter,
            classes: presenter_classes,
            layout: layout)
    end
  end
end
