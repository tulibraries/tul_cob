# frozen_string_literal: true

class CatalogController < ApplicationController
  caches_page :show

  include FacetParamsDedupe
  include BlacklightAdvancedSearch::Controller
  include BlacklightRangeLimit::ControllerOverride
  include Blacklight::Catalog

  include Blacklight::Marc::Catalog
  include ServerErrors
  include LCClassifications
  include Blacklight::Ris::Catalog

  before_action :authenticate_purchase_order!, only: [ :purchase_order, :purchase_order_action ]
  before_action :set_thread_request
  before_action only: :index do
    override_solr_path
    advanced_override_path
    blacklight_config.max_per_page = 50
    if params[:page] && params[:page].to_i > 250
      flash[:error] = t("blacklight.errors.deep_paging")
      redirect_to root_path
    end
  end

  def override_solr_path
    single_word = params["q"]&.split&.count == 1
    quoted_phrase = params["q"]&.match?(/\A["'].*["']\z/)

    if single_word && quoted_phrase
      blacklight_config.solr_path = "single_quoted_search"
    end
  end

  def advanced_override_path
    return unless params["operator"].is_a?(Hash)

    (1..3).each do |i|
      query_param = params["q_#{i}"]
      operator_param = params["operator"]["q_#{i}"]

      if query_param.split.count == 1 && operator_param == "is"
        blacklight_config.solr_path = "single_quoted_search"
        break # Exit early since the solr_path is already set
      end
    end
  end

  helper_method :display_duration

  # TODO: remove once libwizard_tutorial? is no longer a flag
  def self.libwizard_tutorial?
    Proc.new { |context| ::FeatureFlags.libwizard_tutorial?(context.params) }
  end

  configure_blacklight do |config|
    # default advanced config values
    config.advanced_search ||= Blacklight::OpenStructWithHashAccess.new
    config.advanced_search[:url_key] ||= "advanced"
    config.advanced_search[:query_parser] ||= "edismax"
    config.advanced_search[:form_solr_parameters] ||= {}
    config.advanced_search[:form_solr_parameters]["facet.field"] ||= %w(format library_facet language_facet availability_facet)
    config.advanced_search[:form_solr_parameters]["facet.limit"] ||= -1
    config.advanced_search[:form_solr_parameters]["f.language_facet.facet.limit"] ||= -1
    config.advanced_search[:form_solr_parameters]["f.language_facet.facet.sort"] ||= "index"
    config.advanced_search[:fields_row_count] = 3

    config.track_search_session = true
    config.raw_endpoint.enabled = true

    ## Class for sending and receiving requests from a search index
    # config.repository_class = Blacklight::Solr::Repository
    #
    ## Class for converting Blacklight's url parameters to into request parameters for the search index
    # config.search_builder_class = ::SearchBuilder
    #
    ## Model that maps search index responses to the blacklight response model
    # config.response_model = Blacklight::Solr::Response

    ## Default parameters to send to solr for all search-like requests. See also SearchBuilder#processed_parameters
    # config.default_solr_params = {}

    # solr path which will be added to solr base url before the other solr params.
    config.document_solr_path = "document"
    config.solr_path = "search"

    # items to show per page, each number in the array represent another option to choose from.
    config.per_page = [10, 20, 50]

    # Set document specific solr request handler.
    ## Default parameters to send on single-document requests to Solr. These settings are the Blackligt defaults (see SearchHelper#solr_doc_params) or
    ## parameters included in the Blacklight-jetty document requestHandler.
    #
    #config.default_document_solr_params = {
    #  qt: 'document',
    #  ## These are hard-coded in the blacklight 'document' requestHandler
    #  # fl: '*',
    #  # rows: 1,
    #  # q: '{!term f=id v=$id}'
    #}

    # solr field configuration for search results/index views
    config.index.title_field = "title_with_subtitle_truncated_display"
    config.index.display_type_field = "format"
    config.index.document_presenter_class = IndexPresenter

    # solr field configuration for document/show views
    config.show.title_field = "title_with_subtitle_truncated_display"
    #config.show.display_type_field = 'format'
    config.show.document_presenter_class = ShowPresenter

    # solr fields that will be treated as facets by the blacklight application
    #   The ordering of the field names is the order of the display
    #
    # Setting a limit will trigger Blacklight's 'more' facet values link.
    # * If left unset, then all facet values returned by solr will be displayed.
    # * If set to an integer, then "f.somefield.facet.limit" will be added to
    # solr request, with actual solr request being +1 your configured limit --
    # you configure the number of items you actually want _displayed_ in a page.
    # * If set to 'true', then no additional parameters will be sent to solr,
    # but any 'sniffed' request limit parameters will be used for paging, with
    # paging at requested limit -1. Can sniff from facet.limit or
    # f.specific_field.facet.limit solr request params. This 'true' config
    # can be used if you set limits in :default_solr_params, or as defaults
    # on the solr side in the request handler itself. Request handler defaults
    # sniffing requires solr requests to be made with "echoParams=all", for
    # app code to actually have it echo'd back to see it.
    #
    # :show may be set to false if you don't want the facet to be drawn in the
    # facet bar
    #
    # set :index_range to true if you want the facet pagination view to have facet prefix-based navigation
    #  (useful when user clicks "more" on a large facet and wants to navigate alphabetically across a large set of results)
    # :index_range can be an array or range of prefixes that will be used to create the navigation (note: It is case sensitive when searching values)

    # Facet Fields

    # config.add_facet_field 'example_pivot_field', label: 'Pivot Field', :pivot => ['format', 'language_facet']
    # config.add_facet_field 'example_query_facet_field', label: 'Publish Date', :query => {
    #    :years_5 => { label: 'within 5 Years', fq: "pub_date:[#{Time.zone.now.year - 5 } TO *]" },
    #    :years_10 => { label: 'within 10 Years', fq: "pub_date:[#{Time.zone.now.year - 10 } TO *]" },
    #    :years_25 => { label: 'within 25 Years', fq: "pub_date:[#{Time.zone.now.year - 25 } TO *]" }
    # }

    # In order to decide at query time if we want to include ETAS records considered "Online"
    # we define two availability facets and decide which one to show based on the `config.campus_closed` lambda
    # which can evaluate the URL param as well as the env var set feature flag.
    # The `if:` and `unless:` params are the only part evaluated at query time.
    config.campus_closed = lambda { |context, _, __| ::FeatureFlags.campus_closed?(context.params) }
    config.add_facet_field "availability_facet_etas",
      label: "Availability", collapse: false, show: true, home: true, component: true,
      sort: :count,
      query: {
        "At the Library" => { label: "At the Library", fq: 'availability_facet:"At the Library"' },
        "Online" =>  { label: "Online", fq: 'availability_facet:(Online OR "ETAS")' },
        "Rapid Request Access" => { label: "Request Rapid Access",  fq: 'availability_facet:"Request Rapid Access"' }
      },
      if: config.campus_closed
    config.add_facet_field "availability_facet",
      label: "Availability", collapse: false, show: true, home: true, component: true,
      sort: :count,
      query: {
        "At the Library" => { label: "At the Library", fq: 'availability_facet:"At the Library"' },
        "Online" =>  { label: "Online", fq: 'availability_facet:"Online"' },
        "Rapid Request Access" => { label: "Request Rapid Access", fq: 'availability_facet:"Request Rapid Access"' }
      },
      unless: config.campus_closed

    config.add_facet_field "library_facet", label: "Library", presenter: PivotFacetFieldPresenter,
      pivot: ["library_facet", "location_facet"], limit: -1, collapsing: true,  show: true, home: true,
      component: true, pre_process: :pre_process_library_facet, icons: { show: "", hide: "" }
    config.add_facet_field "format", label: "Resource Type", limit: -1, show: true, home: true, component: true
    config.add_facet_field "pub_date_sort", label: "Publication Date", range: true, component: RangeFacetFieldListComponent
    config.add_facet_field "creator_facet", label: "Author/creator", limit: true, show: true, component: true
    config.add_facet_field "subject_facet", label: "Subject", limit: true, show: false, component: true
    config.add_facet_field "donor_info_ms", label: "Donor bookplate", limit: true, show: false, component: true
    config.add_facet_field "genre_ms", label: "Genre", limit: true, show: false, component: true
    config.add_facet_field "language_facet", label: "Language", limit: true, show: true, component: true
    config.add_facet_field "lc_facet", label: "Library of Congress Classification", pivot: ["lc_outer_facet", "lc_inner_facet"], limit: true, show: true, presenter: ClassificationFieldPresenter, component: true, collapsing: true, icons: { show: "", hide: "" }
    config.add_facet_field "genre_facet", label: "Genre", limit: true, show: true, component: true
    config.add_facet_field "subject_topic_facet", label: "Topic" , limit: true, show: true, component: true
    config.add_facet_field "subject_era_facet", label: "Era", limit: true, show: true, component: true
    config.add_facet_field "subject_region_facet", label: "Region", limit: true, show: true, component: true
    config.add_facet_field "collection_ms", label: "Collection Name"
    config.add_facet_field "date_added_facet", label: "Newly Added", query: {
          week_1: { label: "Within Last Week", fq: "date_added_facet:[#{(Date.current - 2.weeks).strftime('%Y%m%d').to_i} TO #{(Date.current - 1.week).strftime('%Y%m%d').to_i}]" },
          months_1: { label: "Within Last Month", fq: "date_added_facet:[#{(Date.current - 1.month).strftime('%Y%m%d').to_i} TO #{(Date.current - 1.week).strftime('%Y%m%d').to_i}]" },
          months_3: { label: "Within Last Three Months", fq: "date_added_facet:[#{(Date.current - 3.months).strftime('%Y%m%d').to_i } TO #{(Date.current - 1.week).strftime('%Y%m%d').to_i}]" },
          months_12: { label: "Within Last Year", fq: "date_added_facet:[#{(Date.current - 1.year).strftime('%Y%m%d').to_i } TO #{(Date.current - 1.week).strftime('%Y%m%d').to_i}]" }
        }

    # Added due to BL pivot field bug. Remove once projectblacklight/blacklight#2463 is fixed.
    config.add_facet_field "location_facet", show: false
    config.add_facet_field "lc_inner_facet", show: false
    config.add_facet_field "lc_outer_facet", show: false
    config.add_facet_field "lc_classification", show: false

    # Have BL send all facet field names to Solr, which has been the default
    # previously. Simply remove these lines if you'd rather use Solr request
    # handler defaults, or have no facets.
    config.add_facet_fields_to_solr_request!

    # solr fields to be displayed in the index (search results) view
    #   The ordering of the field names is the order of the display
    config.add_index_field "format", raw: true, helper_method: :separate_formats, type: :format
    config.add_index_field "imprint_date_display", type: :date
    config.add_index_field "note_summary_display", helper_method: :join, type: :summary
    config.add_index_field "responsibility_truncated_display", label: ""
    config.add_index_field "creator_display", label: "Author/Creator", helper_method: :creator_links
    config.add_index_field "imprint_display", label: "Publication"
    config.add_index_field "imprint_prod_display", label: "Production"
    config.add_index_field "imprint_dist_display", label: "Distribution"
    config.add_index_field "imprint_man_display", label: "Manufacture"
    config.add_index_field "lc_call_number_display", if: :render_lc_call_number_on_index?
    config.add_index_field "url_finding_aid_display", label: "Finding Aid", helper_method: :check_for_full_http_link
    config.add_index_field "availability"
    config.add_index_field "purchase_order_availability", field: "purchase_order", if: false, helper_method: :render_purchase_order_availability, with_po_link: true
    config.add_index_field "bound_with_ids", if: false

    # solr fields to be displayed in the show (single result) view
    #   The ordering of the field names is the order of the display

    config.add_show_field "title_with_subtitle_vern_display", label: "Title Statement", type: :primary
    config.add_show_field "responsibility_display", label: "", type: :responsibility
    config.add_show_field "responsibility_vern_display", label: "", type: :responsibility
    config.add_show_field "url_finding_aid_display", label: "Finding Aid", helper_method: :check_for_full_http_link, type: :primary
    config.add_show_field "title_uniform_display", label: "Uniform title", helper_method: :additional_title_link, type: :primary
    config.add_show_field "title_uniform_vern_display", label: "Uniform title", type: :primary
    config.add_show_field "title_addl_display", label: "Additional titles", helper_method: :additional_title_link, type: :primary
    config.add_show_field "title_addl_vern_display", label: "Additional titles", type: :primary
    config.add_show_field "creator_display", label: "Author/Creator", helper_method: :creator_links, multi: true, type: :primary
    config.add_show_field "creator_vern_display", label: "Author/Creator", helper_method: :creator_links, type: :primary
    config.add_show_field "contributor_display", label: "Contributor", helper_method: :creator_links, multi: true, type: :primary
    config.add_show_field "contributor_vern_display", label: "Contributor", helper_method: :creator_links, type: :primary
    config.add_show_field "format", label: "Resource Type", type: :primary, raw: true, helper_method: :separate_formats
    config.add_show_field "imprint_display", label: "Publication", type: :primary
    config.add_show_field "imprint_prod_display", label: "Production", type: :primary
    config.add_show_field "imprint_dist_display", label: "Distribution", type: :primary
    config.add_show_field "imprint_man_display", label: "Manufacture", type: :primary
    config.add_show_field "edition_display", label: "Edition", type: :primary
    config.add_show_field "date_copyright_display", label: "Copyright Notice", type: :primary
    config.add_show_field "phys_desc_display", label: "Physical Description", type: :primary
    config.add_show_field "collection_ms", label: "Collection", type: :primary, helper_method: :record_page_ms_links, multi: true
    config.add_show_field "title_series_display", label: "Series Title"
    config.add_show_field "title_series_vern_display", label: "Series Title"
    config.add_show_field "volume_series_display", label: "Volume"
    config.add_show_field "duration_display", label: "Duration", helper_method: :display_duration
    config.add_show_field "frequency_display", label: "Frequency"
    config.add_show_field "sound_display", label: "Sound characteristics"
    config.add_show_field "digital_file_display", label: "Digital file characteristics"
    config.add_show_field "video_file_display", label: "Video characteristics"
    config.add_show_field "music_format_display", label: "Format of notated music"
    config.add_show_field "form_work_display", label: "Form of work"
    config.add_show_field "performance_display", label: "Medium of performance"
    config.add_show_field "music_no_display", label: "Music no."
    config.add_show_field "music_key_display", label: "Musical key"
    config.add_show_field "audience_display", label: "Audience"
    config.add_show_field "creator_group_display", label: "Creator/Contributor characteristics"
    config.add_show_field "date_period_display", label: "Time Period"
    config.add_show_field "note_display", label: "Note"
    config.add_show_field "note_award", field: "note_award_display", label: "Awards Note"
    config.add_show_field "note_with_display", label: "With"
    config.add_show_field "note_diss_display", label: "Dissertation Note"
    config.add_show_field "note_biblio_display", label: "Bibliography"
    config.add_show_field "note_toc_display", label: "Contents"
    config.add_show_field "note_bio_display", label: "Biographical or Historical Note"
    config.add_show_field "note_summary_display", label: "Summary"
    config.add_show_field "note_restrictions_display", label: "Access and Restrictions"
    config.add_show_field "note_copyright_display", label: "Copyright Note"
    config.add_show_field "note_references_display", label: "Cited in"
    config.add_show_field "note_cite_display", label: "Cite as"
    config.add_show_field "note_finding_aid_display", label: "Cumulative Index/Finding Aids"
    config.add_show_field "note_custodial_display", label: "Custodial History"
    config.add_show_field "note_binding_display", label: "Binding Note"
    config.add_show_field "note_related_display", label: "Related Materials"
    config.add_show_field "note_accruals_display", label: "Additions to Collection"
    config.add_show_field "note_local_display", label: "Local Note"
    config.add_show_field "donor_info_ms", label: "Donor bookplate", helper_method: :record_page_ms_links, multi: true
    config.add_show_field "subject_display", label: "Subject", helper_method: :subject_links, multi: true
    config.add_show_field "genre_ms", label: "Genre", helper_method: :record_page_ms_links, multi: true
    config.add_show_field "collection_area_display", label: "SCRC Collecting Area"

    # Preceeding Entry fields
    config.add_show_field "continues_display", label: "Continues"
    config.add_show_field "continues_in_part_display", label: "Continues in part"
    config.add_show_field "formed_from_display", label: "Formed from"
    config.add_show_field "absorbed_display", label: "Absorbed"
    config.add_show_field "absorbed_in_part_display", label: "Absorbed in part"
    config.add_show_field "separated_from_display", label: "Separated from"

    # Succeeding Entry fields
    config.add_show_field "continued_by_display", label: "Continued by"
    config.add_show_field "continued_in_part_by_display", label: "Continued in part by"
    config.add_show_field "absorbed_by_display", label: "Absorbed by"
    config.add_show_field "absorbed_in_part_by_display", label: "Absorbed in part by"
    config.add_show_field "split_into_display", label: "Split into"
    config.add_show_field "merged_to_form_display", label: "Merged to form"
    config.add_show_field "changed_back_to_display", label: "Changed back to"

    config.add_show_field "isbn_display", label: "ISBN"
    config.add_show_field "alt_isbn_display", label: "Other ISBN"
    config.add_show_field "issn_display", label: "ISSN"
    config.add_show_field "alt_issn_display", label: "Other ISSN"
    config.add_show_field "pub_no_display", label: "Publication Number"
    config.add_show_field "gpo_display", label: "GPO Item Number"
    config.add_show_field "sudoc_display", label: "SuDOC"
    config.add_show_field "lc_call_number_display", label: "LC Classification"
    config.add_show_field "alma_mms_display", label: "Catalog Record ID"
    config.add_show_field "language_display", label: "Language"
    config.add_show_field "url_more_links_display", label: "Other Links", helper_method: :check_for_full_http_link
    config.add_show_field "electronic_resource_display", label: "Availability", helper_method: :check_for_full_http_link, if: false
    config.add_show_field "bound_with_ids", display: false

    config.add_show_field "po_link", field: "purchase_order", if: false, helper_method: :render_purchase_order_show_link
    config.add_show_field "purchase_order_availability", label: "Request Rapid Access", field: "purchase_order", if: false, helper_method: :render_purchase_order_availability, with_panel: true

    # "fielded" search configuration. Used by pulldown among other places.
    # For supported keys in hash, see rdoc for Blacklight::SearchFields
    #
    # Search fields will inherit the :qt solr request handler from
    # config[:default_solr_parameters], OR can specify a different one
    # with a :qt key/value. Below examples inherit, except for subject
    # that specifies the same :qt as default for our own internal
    # testing purposes.
    #
    # The :key is what will be used to identify this BL search field internally,
    # as well as in URLs -- so changing it after deployment may break bookmarked
    # urls.  A display label will be automatically calculated from the :key,
    # or can be specified manually to be different.

    # This one uses all the defaults set by the solr request handler. Which
    # solr request handler? The one set in config[:default_solr_parameters][:qt],
    # since we aren't specifying it otherwise.

    config.add_search_field "all_fields", label: "All Fields"

    # Now we see how to over-ride Solr request handler defaults, in this
    # case for a BL "search field", which is really a dismax aggregate
    # of Solr search fields.


    config.add_search_field("title") do |field|
      # solr_parameters hash are sent to Solr as ordinary url query params.
      field.solr_parameters = {
        # Curly brackets are required for solr_parameters.
        qf: "${title_qf}",
        pf: "${title_pf}"
      }

      field.solr_adv_parameters = {
        # Curly brackets break solr_adv_parameters.
        qf: "$title_qf",
        pf: "$title_pf"
      }
    end

    config.add_search_field("creator_t", label: "Author/creator/contributor") do |field|
      field.solr_parameters = {
        qf: "${author_qf}",
        pf: "${author_pf}"
      }

      field.solr_adv_parameters = {
        qf: "$author_qf",
        pf: "$author_pf"
      }
    end

    # Specifying a :qt only to show it's possible, and so our internal automated
    # tests can test it. In this case it's the same as
    # config[:default_solr_parameters][:qt], so isn't actually neccesary.
    config.add_search_field("subject") do |field|
      field.solr_parameters = {
        qf: "${subject_qf}",
        pf: "${subject_pf}"
      }

      field.solr_adv_parameters = {
        qf: "$subject_qf",
        pf: "$subject_pf"
      }
    end

    config.add_search_field("genre") do |field|
      field.include_in_simple_select = false
      field.solr_parameters = {
        qf: "genre_t",
      }
    end

    config.add_search_field("publisher_t", label: "Publisher") do |field|
      field.include_in_simple_select = false
      field.solr_parameters = {
        qf: "publisher_t",
      }
    end

    config.add_search_field("title_series_t", label: "Series Title") do |field|
      field.include_in_simple_select = false
      field.solr_parameters = {
        qf: "title_series_t",
      }
    end

    config.add_search_field("note_t", label: "Description") do |field|
      field.include_in_simple_select = false
      field.solr_parameters = {
        qf: %w[note_t note_with_t note_diss_t note_biblio_t note_toc_t note_restrictions_t note_references_t note_summary_t note_cite_t note_copyright_t note_bio_t note_finding_aid_t note_custodial_t note_binding_t note_related_t note_accruals_t note_local_t].join(" ")
      }
    end

    config.add_search_field("isbn_t", label: "ISBN") do |field|
      field.solr_parameters = {
        qf: "isbn_t",
      }
    end

    config.add_search_field("issn_t", label: "ISSN") do |field|
      field.solr_parameters = {
        qf: "issn_t",
      }
    end

    config.add_search_field("call_number_t", label: "Call Number") do |field|
      field.include_in_advanced_search = true
      field.include_in_simple_select = false
      field.solr_parameters = {
        qf: "call_number_t",
      }
    end

    config.add_search_field("alma_mms_t", label: "Catalog Record ID") do |field|
      field.include_in_simple_select = false
      field.solr_parameters = {
        qf: "alma_mms_t",
      }
    end

    # "sort results by" select (pulldown)
    # label in pulldown is followed by the name of the SOLR field to sort by and
    # whether the sort is ascending or descending (it must be asc or desc
    # except in the relevancy case).

    config.add_sort_field "score desc, pub_date_sort desc, title_sort asc", label: "relevance"
    config.add_sort_field "pub_date_sort desc, title_sort asc", label: "date (new to old)"
    config.add_sort_field "pub_date_sort asc, title_sort asc", label: "date (old to new)"
    config.add_sort_field "author_sort asc, title_sort asc", label: "author/creator (A to Z)"
    config.add_sort_field "author_sort desc, title_sort asc", label: "author/creator (Z to A)"
    config.add_sort_field "title_sort asc, pub_date_sort desc", label: "title (A to Z)"
    config.add_sort_field "title_sort desc, pub_date_sort desc", label: "title (Z to A)"
    config.add_sort_field "lc_call_number_sort asc, pub_date_sort desc", label: "lc classification (A to Z)"
    config.add_sort_field "lc_call_number_sort desc, pub_date_sort desc", label: "lc classification (Z to A)"
    config.add_sort_field "date_added_facet desc, title_sort asc", label: "newly added"

    # If there are more than this many search results, no spelling ("did you
    # mean") suggestion is offered.
    config.spell_max = 5

    # Configuration for autocomplete suggestor
    config.autocomplete_enabled = false
    config.autocomplete_path = "suggest"

    config.add_nav_action :library_account, partial: "/users/account_link", if: :user_signed_in?

    # marc config
    # Do not show library_view link
    config.show.document_actions.delete(:librarian_view)
    #config.add_show_tools_partial(:ris, label: "RIS File", if: :render_ris_action?, modal: false, path: :ris_path)
    # Do not show endnotes for beta release
    config.show.document_actions.delete(:endnote)
    config.add_show_tools_partial(:citation)
    # Need to add citation for side effect only.
    config.show.document_actions.delete(:citation)
    config.show.document_actions.delete(:refworks)

    # Document results tools
    config.add_results_document_tool(:bookmark, partial: "bookmark_control", if: :render_bookmarks_control?)

    # Results collection tools
    config.add_results_collection_tool(:sort_widget)
    config.add_results_collection_tool(:per_page_widget)
    config.add_results_collection_tool(:view_type_group)

    # Show tools
    config.add_show_tools_partial(:bookmark, partial: "bookmark_control", if: :render_bookmarks_control?)
    config.add_show_tools_partial(:email, callback: :email_action, validator: :validate_email_params)
    config.add_show_tools_partial(:ris, label: "RIS file (for Zotero, Mendeley, Endnote)", modal: false, path: :ris_path)

    # Nav tools
    config.add_nav_action(:bookmark, partial: "blacklight/nav/bookmark", if: :render_bookmarks_control?)

    config.show.document_actions.delete(:email) if Rails.configuration.features[:email_document_action_disabled]

  end

  def availability
    ids = params["id_list"].split(",")
    response = Alma::Bib.get_availability(ids)
    render json: { availability: response.availability }.to_json
  end

  # Can be overridden by subclass
  def show_sidebar?
    has_search_parameters?
  end

  helper_method :show_sidebar?

  def text_this_message_body(params)
    "#{params[:title]}\n" +
    "#{params[:location]}"
  end

  def creator_links(args)
    creator = args[:document][args[:field]] || []
    base_path = helpers.base_path
    creator.map do |creator_data|
      begin
        creator_data = JSON.parse(creator_data)
        relation = creator_data["relation"]
        name = creator_data["name"]
        role = creator_data["role"]
      rescue JSON::ParserError
        name, role = creator_data.split("|")
      end

      creator_query = view_context.send(:url_encode, name)
      name_link = view_context.link_to(name, base_path + "?f[creator_facet][]=#{creator_query}") if name.present?

      ActiveSupport::SafeBuffer.new([ relation,
        name_link,
        role ].select(&:present?).join(" "))
    end
  end

  def display_duration(args)
    args[:value]&.map { |v| v.scan(/([0-9]{2})/).join(":") }
  end

  # Overrides CatalogController.invalid_document_id_error
  # Overridden so that we can use our own 404 error handling setup.
  def invalid_document_id_error(exception)
    error_info = {
      "status" => "404",
      "error"  => "#{exception.class}: #{exception.message}"
    }

    respond_to do |format|
      format.xml  { render xml: error_info, status: :not_found }
      format.json { render json: error_info, status: :not_found }

      # default to HTML response, even for other non-HTML formats we don't
      # neccesarily know about, seems to be consistent with what Rails4 does
      # by default with uncaught ActiveRecord::RecordNotFound in production
      format.any do
        # use standard, possibly locally overridden, 404.html file. Even for
        # possibly non-html formats, this is consistent with what Rails does
        # on raising an ActiveRecord::RecordNotFound. Rails.root IS needed
        # for it to work under testing, without worrying about CWD.
        render "errors/not_found", status: :not_found
      end
    end
  end

  def raise_bad_range_limit(exception)
    flash[:notice] = exception.message
    redirect_to request.referrer || root_url
  end

  def purchase_order
    (@response, @document) = search_service.fetch(params["id"])
    render layout: false
  end

  def purchase_order_action
    (_, document) = search_service.fetch(params["id"])

    email = current_user&.email || params[:to]
    name = current_user&.name

    from = { email:, name: }

    mail = PurchaseOrderMailer.purchase_order(document, { from:, message: params[:message] }, url_options)
    log = { type: "purchase_order", user: current_user.id, mms_id: document.id }
    if mail.respond_to? :deliver_now
      do_with_json_logger(log) { mail.deliver_now }
    else
      do_with_json_logger(log) { mail.deliver }
    end

    redirect_back(fallback_location: root_path, success: "Your request has been submitted.")
  end

  def authenticate_purchase_order!
    authenticate_user!
    message = "You do not have access to purchase order items."
    to_the_future = { fallback_location: root_path, alert: message }

    redirect_back(**to_the_future) unless current_user.can_purchase_order?
  end


  # Override index because we don't show any results at /catalog when
  # there are no parameters, and so we don't need to bother solr
  def index
    if has_search_parameters? || advanced_controller?
      super
    else
      respond_to do |format|
        format.html { store_preferred_view }
      end
    end
  end

  private
    def catalog?
      self.class == CatalogController
    end

    def advanced_controller?
      self.class == AdvancedController
    end

    # Allow access to request outside of controller context.
    def set_thread_request
      LogUtils.request = request
    end
end
