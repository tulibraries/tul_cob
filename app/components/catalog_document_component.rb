# frozen_string_literal: true

class CatalogDocumentComponent < Blacklight::DocumentComponent
  def before_render
    if view_partials.present?
      with_body do
        helpers.safe_join(
          view_partials.map do |view_partial|
            helpers.render_document_partial(
              document,
              view_partial,
              component: self,
              document_counter: counter
            )
          end
        )
      end
    else
      super
    end
  end
end
