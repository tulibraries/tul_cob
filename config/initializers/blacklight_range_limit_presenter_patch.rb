# frozen_string_literal: true

# BlacklightRangeLimit assumes a display facet is always available, but Primo
# searches can skip the HTTP request entirely (e.g., landing page) and leave
# presenters without one. Provide a lightweight fallback to keep the range
# components happy until a real response arrives.
Rails.application.config.to_prepare do
  next unless defined?(BlacklightRangeLimit::FacetFieldPresenter)

  BlacklightRangeLimit::FacetFieldPresenter.prepend(
    Module.new do
      class NullRangeResponse
        def dig(*)
          nil
        end

        def [](*)
          nil
        end

        def total
          0
        end

        def grouped?
          false
        end

        def grouped
          {}
        end
      end

      def display_facet
        super || (@display_facet ||= build_fallback_display_facet)
      end

      private

      def build_fallback_display_facet
        response = fallback_response || NullRangeResponse.new

        fallback_facet_class(response).new(
          facet_field.field,
          [],
          response:
        )
      end

      def fallback_facet_class(response)
        return Blacklight::Solr::Response::Facets::NullFacetField unless primo_context?(response)

        Blacklight::PrimoCentral::Facets::FacetField
      rescue NameError
        Blacklight::Solr::Response::Facets::NullFacetField
      end

      def primo_context?(response)
        response_is_primo = defined?(Blacklight::PrimoCentral::Response) &&
                            response.is_a?(Blacklight::PrimoCentral::Response)
        return true if response_is_primo

        defined?(Blacklight::PrimoCentral::Response) &&
          blacklight_config&.response_model == Blacklight::PrimoCentral::Response
      end

      def fallback_response
        assigns = view_context&.assigns || {}
        assigns['response'] ||
          assigns[:response] ||
          view_context&.controller&.instance_variable_get(:@response) ||
          view_context&.controller&.view_assigns&.[]('response') ||
          view_context&.controller&.view_assigns&.[](:response)
      end
    end
  )
end
