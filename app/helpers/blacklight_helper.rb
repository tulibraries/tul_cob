# frozen_string_literal: true

module BlacklightHelper
  include Blacklight::BlacklightHelperBehavior


  # Override/Revert to v7.3.0 version due to error introduced in v7.4.0
  #
  # REF: projectblacklight/blacklight#2234
  #
  # TODO: remove once issue gets fixed upstream.
  def link_to_document(doc, field_or_opts = nil, opts = { counter: nil })
    label = case field_or_opts
            when NilClass
              index_presenter(doc).label document_show_link_field(doc), opts
            when Hash
              opts = field_or_opts
              index_presenter(doc).label document_show_link_field(doc), opts
            when Proc, Symbol
              Deprecation.warn(self, "passing a #{field_or_opts.class} to link_to_document is deprecated and will be removed in Blacklight 8")
              Deprecation.silence(Blacklight::IndexPresenter) do
                index_presenter(doc).label field_or_opts, opts
              end
            else # String
              field_or_opts
    end

    link_to label, search_state.url_for_document(doc), document_link_params(doc, opts)
  end
end
