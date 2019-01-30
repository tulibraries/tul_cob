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
    config.add_index_field "availability"

    # Index fields
    config.add_index_field "id", label: "AZ ID"
    config.add_index_field "az_vendor_id_display", label: "AZ Vendor ID"
    config.add_index_field "note_display", label: "Note", raw: true, helper_method: :join

    # Show fields
    config.add_show_field "id", label: "AZ ID"
    config.add_show_field "note_display", label: "Note", raw: true, helper_method: :join
    config.add_show_field "electronic_resource_display", label: "Availability", helper_method: :check_for_full_http_link, if: false

    # Search fields
    config.add_search_field("title") do |field|
      # solr_parameters hash are sent to Solr as ordinary url query params.
      field.solr_parameters = { 'spellcheck.dictionary': "title" }
      field.solr_local_parameters = {
        qf: "$title_qf",
        pf: "$title_pf"
      }
    end

    config.add_search_field("subject") do |field|
      field.solr_parameters = { 'spellcheck.dictionary': "subject" }
      field.qt = "search"
      field.solr_local_parameters = {
        qf: "$subject_qf",
        pf: "$subject_pf"
      }
    end
  end

  def join(args)
    args[:value].join
  end
end
