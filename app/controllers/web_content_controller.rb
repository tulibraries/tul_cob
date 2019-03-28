# frozen_string_literal: true

class WebContentController < CatalogController
  include CatalogConfigReinit


  configure_blacklight do |config|
    config.document_model = SolrWebContentDocument
    config.connection_config = config.connection_config.dup
    config.connection_config[:url] = config.connection_config[:web_content_url]
    config.default_solr_params = {
        wt: "json",
        fl: %w[
          * ].join(",")
    }

    config.index.title_field = "title_display"

    # Facet fields
    config.add_facet_field "category_facet", label: "Category", limit: true, show: true

    # Index fields
    config.add_index_field "description_display", label: "Description", raw: true
    config.add_index_field "phone_number_display", label: "Phone Number"
    config.add_index_field "photo_display", label: "Thumbnail"

    # Search fields
    config.add_search_field "all_fields", label: "All Fields"

    config.add_search_field("title") do |field|
      # solr_parameters hash are sent to Solr as ordinary url query params.
      field.solr_parameters = { 'spellcheck.dictionary': "title" }
      field.solr_local_parameters = {
        qf: "$title_t_qf $alt_names_t_qf",
        pf: "$title_t_pf $alt_names_t_pf"
      }
    end

    # Sort fields.
    config.add_sort_field "score desc, title_sort asc", label: "relevance"
    config.add_sort_field "title_sort asc", label: "title (A to Z)"
    config.add_sort_field "title_sort desc", label: "title (Z to A)"
  end
end
