# frozen_string_literal: true

class DatabasesController < CatalogController
  include CatalogConfigReinit

  helper_method :join

  configure_blacklight do |config|
    config.advanced_search[:fields_row_count] = 2
    config.advanced_search[:form_solr_parameters]["facet.field"] = %w(subject_facet format)
    config.document_model = SolrDatabaseDocument
    config.connection_config = config.connection_config.dup
    config.connection_config[:url] = config.connection_config[:az_url]
    config.document_solr_path = "document"

    # Do not inherit default solr configs from the catalog.
    config.default_solr_params =
      config.default_document_solr_params = config.fetch_many_document_params = {}

    # Facet fields
    config.add_facet_field "az_subject_facet", field: "subject_facet", label: "Subject", limit: true, show: true, collapse: false
    config.add_facet_field "az_format", field: "format", label: "Database Type", limit: -1, show: true, home: true, collapse: false
    config.add_facet_field "az_availability_facet", field: "availability_facet", label: "Access", home: true

    # Index fields
    config.add_index_field "format", label: "Database Type", raw: true, helper_method: :separate_formats
    config.add_index_field "note_display", label: "Description", raw: true, helper_method: :join
    config.add_index_field "availability"

    # Show fields
    config.add_show_field "note_display", label: "Description", raw: true, helper_method: :join
    config.add_show_field "electronic_resource_display", label: "Availability", helper_method: :check_for_full_http_link, if: false
    config.add_show_field "subject_display", label: "Subject", helper_method: :database_subject_links, multi: true
    config.add_show_field "format", label: "Database Type", helper_method: :database_type_links, multi: true
    config.add_show_field "az_vendor_name_display", label: "Database Vendor"
    config.add_show_field "id", label: "Database Record ID"
    config.add_show_field "database_display", if: false

    # Search fields
    config.add_search_field "all_fields", label: "All Fields"

    config.add_search_field("title") do |field|
      field.solr_parameters = {
        qt: "search",
        qf: "${title_qf}",
        pf: "${title_pf}",
        "spellcheck.dictionary": "title",
      }

      field.solr_adv_parameters = {
        qf: "$title_qf",
        pf: "$title_pf",
      }
    end

    config.add_search_field("subject") do |field|
      field.solr_parameters = {
        qt: "search",
        qf: "${subject_qf}",
        pf: "${subject_pf}",
        "spellcheck.dictionary": "subject",
      }

      field.solr_adv_parameters = {
        qf: "$subject_qf",
        pf: "$subject_pf",
      }
    end


    # Sort fields.
    config.add_sort_field "score desc, title_sort asc", label: "relevance"
    config.add_sort_field "title_sort asc", label: "title (A to Z)"
    config.add_sort_field "title_sort desc", label: "title (Z to A)"

    # Remove show and index doc actions.
    config.index.document_actions = Blacklight::NestedOpenStructWithHashAccess.new({})
    config.show.document_actions = Blacklight::NestedOpenStructWithHashAccess.new({})

  end

  def join(args)
    args[:value].join
  end
end
