# frozen_string_literal: true

class WebContentController < CatalogController
  include CatalogConfigReinit


  configure_blacklight do |config|
    config.document_model = SolrWebContentDocument
    config.connection_config = config.connection_config.dup
    config.connection_config[:url] = config.connection_config[:web_content_url]
    config.track_search_session = false
    config.default_solr_params = {
        wt: "json",
        fl: %w[
          * ].join(",")
    }

    config.index.title_field = "web_title_display"

    # Facet fields
    config.add_facet_field "web_type_pivot_facet",
      label: "Content Type",
      collapse: false,
      helper_method: :pluralize_types,
      pivot: ["web_type_pivot_facet", "web_content_type_facet"]

    # Index fields
    config.add_index_field "web_job_title_display", label: "Job Title"
    config.add_index_field "web_base_url_display", label: "Link"
    config.add_index_field "web_description_display", label: "Description"
    config.add_index_field "web_email_address_display", label: "Email Address"
    config.add_index_field "web_phone_number_display", label: "Phone Number"
    config.add_index_field "web_specialties_display", label: "Specialties"
    config.add_index_field "web_subject_display", label: "Subject"
    config.add_index_field "web_group_type_display", label: "Group Type"
    config.add_index_field "web_blurb_display", label: "Blurb"
    config.add_index_field "web_tags_display", label: "Tags"
    config.add_index_field "web_link_display", label: "Link"

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
