# frozen_string_literal: true

class CatalogDocumentComponent < Blacklight::DocumentComponent
  def before_render
    if @view_partials.present?
      with_body do
        helpers.render_document_partials(
          @presenter.document,
          @view_partials,
          component: self,
          document_counter: @counter
        )
      end
    else
      super
    end
  end
end
