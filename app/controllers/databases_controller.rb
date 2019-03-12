# frozen_string_literal: true

class DatabasesController < CatalogController
  include CatalogConfigReinit

  helper_method :join

  add_breadcrumb "Databases", :back_to_databases_path, options: { id: "breadcrumbs_database" }, only: [ :show ]
  add_breadcrumb "Record", :solr_database_document_path, only: [ :show ]

  configure_blacklight do |config|
    config.document_model = SolrDatabaseDocument
    config.connection_config = config.connection_config.dup
    config.connection_config[:url] = config.connection_config[:az_url]
    config.default_solr_params = {
        wt: "json",
        fl: %w[
          *
          url_finding_aid_display:[json]
          url_more_links_display:[json]
          electronic_resource_display:[json] ].join(",")
    }

    # Facet fields
    config.add_facet_field "availability_facet", label: "Availability", home: true, collapse: false
    config.add_facet_field "subject_facet", label: "Subject", limit: true, show: true
    config.add_facet_field "format", label: "Resource Type", limit: -1, show: true, home: true

    # Index fields
    config.add_index_field "note_display", label: "Description", raw: true, helper_method: :join
    config.add_index_field "format", label: "Resource Type", raw: true, helper_method: :separate_formats
    config.add_index_field "availability"

    # Show fields
    config.add_show_field "note_display", label: "Description", raw: true, helper_method: :join
    config.add_show_field "electronic_resource_display", label: "Availability", helper_method: :check_for_full_http_link, if: false
    config.add_show_field "subject_display", label: "Subject", helper_method: :subject_links, multi: true
    config.add_show_field "az_vendor_name_display", label: "Database Vendor"
    config.add_show_field "id", label: "Database Record ID"

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

    config.add_search_field("subject") do |field|
      field.solr_parameters = { 'spellcheck.dictionary': "subject" }
      field.qt = "search"
      field.solr_local_parameters = {
        qf: "$subject_facet_qf",
        pf: "$subject_facet_pf"
      }
    end

    # Sort fields.
    config.add_sort_field "score desc, title_sort asc", label: "relevance"
    config.add_sort_field "title_sort asc", label: "title (A to Z)"
    config.add_sort_field "title_sort desc", label: "title (Z to A)"
  end

  def join(args)
    args[:value].join
  end
end
