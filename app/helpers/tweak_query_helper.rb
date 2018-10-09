# frozen_string_literal: true

module TweakQueryHelper
  def render_solr_search_tweaks
    if ENV["SOLR_SEARCH_TWEAK_ENABLE"] != "on" ||
        blacklight_config.document_model != SolrDocument
      return
    end

    fields = blacklight_config.default_solr_params
      .merge(params.to_h.inject({}) { |acc, (k, v)| acc[k.to_sym] = v; acc })
      .select { |name, value| name.match?(/(qf$|pf$)/) }

    render partial: "tweak_solr_query_form", locals: { fields: fields }
  end

  def titleize_field(name)
    "#{name}".titleize
      .gsub("Qf", "Query Fields (qf)")
      .gsub("Pf", "Phrase Fields (pf)")
  end
end
