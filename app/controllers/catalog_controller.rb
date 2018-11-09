# frozen_string_literal: true

require "twilio-ruby"

class CatalogController < ApplicationController
  include BlacklightAdvancedSearch::Controller

  include BlacklightRangeLimit::ControllerOverride

  include Blacklight::Catalog

  include BlacklightAlma::Availability

  include Blacklight::Marc::Catalog

  include Blacklight::Ris::Catalog

  before_action :authenticate_user!, only: [ :purchase_order, :purchase_order_action ]

  add_breadcrumb "More", :back_to_catalog_path, only: [ :show ], if: :catalog?
  add_breadcrumb "More", :back_to_catalog_path, if: :advanced_controller?
  add_breadcrumb "Record", :solr_document_path, only: [ :show ], if: :catalog?
  add_breadcrumb I18n.t(:catalog_advanced_search), :advanced_search_path,
    only: [ :index ], if: :advanced_controller?

  helper_method :browse_creator
  helper_method :display_duration
  rescue_from ::BlacklightRangeLimit::InvalidRange,
    with: :raise_bad_range_limit

  configure_blacklight do |config|
    config.index.document_presenter_class = CatalogIndexPresenter

    # default advanced config values
    config.advanced_search ||= Blacklight::OpenStructWithHashAccess.new
    #config.advanced_search[:qt] ||= 'advanced'
    config.advanced_search[:url_key] ||= "advanced"
    config.advanced_search[:query_parser] ||= "edismax"
    config.advanced_search[:form_solr_parameters] ||= {}
    config.advanced_search[:form_solr_parameters]["facet.field"] ||= %w(format library_facet language_facet availability_facet)
    config.advanced_search[:fields_row_count] = 3

    ## Class for sending and receiving requests from a search index
    # config.repository_class = Blacklight::Solr::Repository
    #
    ## Class for converting Blacklight's url parameters to into request parameters for the search index
    # config.search_builder_class = ::SearchBuilder
    #
    ## Model that maps search index responses to the blacklight response model
    # config.response_model = Blacklight::Solr::Response

    ## Default parameters to send to solr for all search-like requests. See also SearchBuilder#processed_parameters
    config.default_solr_params = {
      wt: "json",
      fl: %w[
        id
        score
        availability_facet
        holdings_display
        holdings_with_no_items_display
        call_number_display
        call_number_alt_display
        creator_display
        contributor_display
        electronic_resource_display
        format
        imprint_display
        imprint_prod_display
        imprint_dist_display
        imprint_man_display
        library_facet
        location_display
        pub_date
        holdings_summary_display
        title_series_display
        title_statement_display
        title_truncated_display
        title_uniform_display
        isbn_display
        lccn_display
        url_finding_aid_display
        bound_with_ids
        purchase_order
        electronic_collection_id
        electronic_service_id
      ].join(" "),
      defType: "edismax",
      echoParams: "explicit",
      rows: "10",
      mm: [
       "5<-1",
        URI.escape("8<75%")
          ],
      "mm.autorelax" => "true",
      lowercaseOperators: false,
      ps: "3",
      tie: "0.01",
      qf: %w[
        title_unstem_search^100000
        subtitle_unstem_search^50000
        title_t^25000
        subtitle_t^10000
        title_statement_unstem_search^15000
        title_statement_t^5000
        title_uniform_unstem_search^15000
        title_uniform_t^5000
        title_addl_unstem_search^5000
        title_addl_t^2500
        title_added_entry_unstem_search^1500
        title_added_entry_t^1250
        subject_topic_unstem_search^1000
        subject_unstem_search^750
        subject_topic_facet^625
        subject_t^500
        creator_unstem_search^250
        creator_t^100
        subject_addl_unstem_search^250
        subject_addl_t^50
        title_series_unstem_search^25
        title_series_t^10
        isbn_t^5
        issn_t^5
        text
      ].join(" "),
      pf: %w[
        title_unstem_search^1000000
        subtitle_unstem_search^500000
        title_t^250000
        subtitle_t^100000
        title_statement_unstem_search^150000
        title_statement_t^50000
        title_uniform_unstem_search^150000
        title_uniform_t^50000
        title_addl_unstem_search^50000
        title_addl_t^25000
        title_added_entry_unstem_search^15000
        title_added_entry_t^12500
        subject_topic_unstem_search^10000
        subject_unstem_search^7500
        subject_topic_facet^6250
        subject_t^5000
        note_toc_unstem_search~0^6000
        note_summary_unstem_search~0^6000
        note_toc_unstem_search^1000
        note_summary_unstem_search^1000
        creator_unstem_search~2^7500
        creator_unstem_search^2500
        creator_t^1000
        subject_addl_unstem_search^2500
        subject_addl_t^500
        title_series_unstem_search^250
        title_series_t^100
        text^10
      ].join(" "),
      author_qf: %w[
        creator_unstem_search^200
        creator_t^20
      ].join(" "),
      author_pf: %w[
        creator_unstem_search^2000
        creator_t^200
      ].join(" "),
      title_qf: %w[
        title_unstem_search^50000
        subtitle_unstem_search^25000
        title_uniform_unstem_search^15000
        title_addl_unstem_search^10000
        title_t^5000
        subtitle_t^2500
        title_uniform_t^150
        title_addl_t^100
        title_added_entry_unstem_search^50
        title_added_entry_t^10
        title_series_unstem_search^5
        title_series_t
      ].join(" "),
      title_pf: %w[
        title_unstem_search^500000
        subtitle_unstem_search^250000
        title_uniform_unstem_search^150000
        title_addl_unstem_search^100000
        title_t^50000
        subtitle_t^25000
        title_uniform_t^1500
        title_addl_t^1000
        title_added_entry_unstem_search^500
        title_added_entry_t^100
        title_series_t^50
        title_series_unstem_search^10
      ].join(" "),
      subject_qf: %w[
        subject_topic_unstem_search^200
        subject_unstem_search^125
        subject_topic_facet^100
        subject_t^50
        subject_addl_unstem_search^10
        subject_addl_t
      ].join(" "),
      subject_pf: %w[
        subject_topic_unstem_search^2000
        subject_unstem_search^1250
        subject_t^1000
        subject_topic_facet^500
        subject_addl_unstem_search^100
        subject_addl_t^10
      ].join(" "),
      facet: "true",
      spellcheck: "false",
      sow: "false",
      bq: [
          "pub_date_tdt:[NOW/DAY-10YEAR TO NOW/DAY]^3500",
          "(library_based_boost_t:* -no_boost)^1000"],
      fq: %w[
        -suppress_items_b:*
      ]
    }

    # solr path which will be added to solr base url before the other solr params.
    #config.solr_path = 'select'

    # items to show per page, each number in the array represent another option to choose from.
    #config.per_page = [10,20,50,100]

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
    config.index.title_field = "title_truncated_display"
    config.index.display_type_field = "format"

    # solr field configuration for document/show views
    config.show.title_field = "title_statement_display"
    #config.show.display_type_field = 'format'

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

    config.add_facet_field "availability_facet", label: "Availability", home: true, collapse: false
    config.add_facet_field "library_facet", label: "Library", limit: -1, show: true, home: true
    config.add_facet_field "format", label: "Resource Type", limit: -1, show: true, home: true
    config.add_facet_field "pub_date_sort", label: "Date", range: true
    config.add_facet_field "creator_facet", label: "Author/creator", limit: true, show: true
    config.add_facet_field "subject_facet", label: "Subject", limit: true, show: false
    config.add_facet_field "subject_topic_facet", label: "Topic" , limit: true, show: true
    config.add_facet_field "subject_era_facet", label: "Era", limit: true, show: true
    config.add_facet_field "subject_region_facet", label: "Region", limit: true, show: true
    config.add_facet_field "genre_facet", label: "Genre", limit: true, show: true
    config.add_facet_field "language_facet", label: "Language", limit: true, show: true


    # Have BL send all facet field names to Solr, which has been the default
    # previously. Simply remove these lines if you'd rather use Solr request
    # handler defaults, or have no facets.
    config.add_facet_fields_to_solr_request!

    # solr fields to be displayed in the index (search results) view
    #   The ordering of the field names is the order of the display

    config.add_index_field "imprint_display", label: "Publication"
    config.add_index_field "imprint_prod_display", label: "Production"
    config.add_index_field "imprint_dist_display", label: "Distribution"
    config.add_index_field "imprint_man_display", label: "Manufacture"
    config.add_index_field "creator_display", label: "Author/Creator", helper_method: :creator_index_separator
    config.add_index_field "format", label: "Resource Type", raw: true, helper_method: :separate_formats
    config.add_index_field "url_finding_aid_display", label: "Finding Aid", helper_method: :check_for_full_http_link
    config.add_index_field "availability"


    # solr fields to be displayed in the show (single result) view
    #   The ordering of the field names is the order of the display

    config.add_show_field "title_statement_vern_display", label: "Title Statement"
    config.add_show_field "url_finding_aid_display", label: "Finding Aid", helper_method: :check_for_full_http_link
    config.add_show_field "title_uniform_display", label: "Uniform title", helper_method: :list_with_links
    config.add_show_field "title_uniform_vern_display", label: "Uniform title"
    config.add_show_field "title_addl_display", label: "Additional titles", helper_method: :list_with_links
    config.add_show_field "title_addl_vern_display", label: "Additional titles"
    config.add_show_field "creator_display", label: "Author/Creator", helper_method: :browse_creator, multi: true
    config.add_show_field "creator_vern_display", label: "Author/Creator", helper_method: :browse_creator
    config.add_show_field "contributor_display", label: "Contributor", helper_method: :browse_creator, multi: true
    config.add_show_field "contributor_vern_display", label: "Contributor", helper_method: :browse_creator
    config.add_show_field "format", label: "Resource Type"
    config.add_show_field "imprint_display", label: "Publication"
    config.add_show_field "imprint_prod_display", label: "Production"
    config.add_show_field "imprint_dist_display", label: "Distribution"
    config.add_show_field "imprint_man_display", label: "Manufacture"
    config.add_show_field "edition_display", label: "Edition"
    config.add_show_field "date_copyright_display", label: "Copyright Notice"
    config.add_show_field "phys_desc_display", label: "Physical Description"
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
    config.add_show_field "note_with_display", label: "With"
    config.add_show_field "note_diss_display", label: "Dissertation Note"
    config.add_show_field "note_biblio_display", label: "Bibliography"
    config.add_show_field "note_toc_display", label: "Contents"
    config.add_show_field "note_restrictions_display", label: "Access and Restrictions"
    config.add_show_field "note_references_display", label: "Cited in"
    config.add_show_field "note_summary_display", label: "Summary"
    config.add_show_field "note_cite_display", label: "Cite as"
    config.add_show_field "note_copyright_display", label: "Copyright Note"
    config.add_show_field "note_bio_display", label: "Biographical or Historical Note"
    config.add_show_field "note_finding_aid_display", label: "Finding Aids"
    config.add_show_field "note_custodial_display", label: "Custodial History"
    config.add_show_field "note_binding_display", label: "Binding Note"
    config.add_show_field "note_related_display", label: "Related Materials"
    config.add_show_field "note_accruals_display", label: "Additions to Collection"
    config.add_show_field "note_local_display", label: "Local Note"
    config.add_show_field "subject_display", label: "Subject", helper_method: :subject_links, multi: true
    config.add_show_field "collection_display", label: "Collection"
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

    #config.add_show_field 'call_number', label: 'Call Number'
    #config.add_show_field 'call_number_alt', label: 'Alternative Call Number'
    config.add_show_field "isbn_display", label: "ISBN"
    config.add_show_field "alt_isbn_display", label: "Other ISBN"
    config.add_show_field "issn_display", label: "ISSN"
    config.add_show_field "alt_issn_display", label: "Other ISSN"
    config.add_show_field "pub_no_display", label: "Publication Number"
    config.add_show_field "gpo_display", label: "GPO Item Number"
    config.add_show_field "sudoc_display", label: "SuDOC"
    config.add_show_field "alma_mms_display", label: "Catalog Record ID"
    config.add_show_field "language_display", label: "Language"
    config.add_show_field "url_more_links_display", label: "Other Links", helper_method: :check_for_full_http_link
    config.add_show_field "electronic_resource_display", label: "Availability", helper_method: :check_for_full_http_link, if: false
    config.add_show_field "bound_with_ids", display: false

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
      field.solr_parameters = { 'spellcheck.dictionary': "title" }
      field.solr_local_parameters = {
        qf: "$title_qf",
        pf: "$title_pf"
      }
    end

    # Are we using this anywhere?
    config.add_search_field("author") do |field|
      field.include_in_simple_select = false
      field.include_in_advanced_search = false
      field.solr_parameters = { 'spellcheck.dictionary': "author" }
      field.solr_local_parameters = {
        qf: "$author_qf",
        pf: "$author_pf"
      }
    end

    config.add_search_field("creator_t", label: "Author/creator/contributor") do |field|
      field.solr_parameters = { 'spellcheck.dictionary': "author" }
      field.solr_local_parameters = {
        qf: "$author_qf",
        pf: "$author_pf"
      }
    end

    # Specifying a :qt only to show it's possible, and so our internal automated
    # tests can test it. In this case it's the same as
    # config[:default_solr_parameters][:qt], so isn't actually neccesary.
    config.add_search_field("subject") do |field|
      field.solr_parameters = { 'spellcheck.dictionary': "subject" }
      field.qt = "search"
      field.solr_local_parameters = {
        qf: "$subject_qf",
        pf: "$subject_pf"
      }
    end

    config.add_search_field("publisher_t", label: "Publisher") do |field|
      field.include_in_simple_select = false
      field.solr_local_parameters = {
        qf: "publisher_t",
      }
    end

    config.add_search_field("title_series_t", label: "Series Title") do |field|
      field.include_in_simple_select = false
      field.solr_local_parameters = {
        qf: "title_series_t",
      }
    end

    config.add_search_field("note_t", label: "Description") do |field|
      field.include_in_simple_select = false
      field.solr_local_parameters = {
        qf: %w[note_t note_with_t note_diss_t note_biblio_t note_toc_t note_restrictions_t note_references_t note_summary_t note_cite_t note_copyright_t note_bio_t note_finding_aid_t note_custodial_t note_binding_t note_related_t note_accruals_t note_local_t].join(" ")
      }
    end

    config.add_search_field("isbn_t", label: "ISBN") do |field|
      field.solr_local_parameters = {
        qf: "isbn_t",
      }
    end

    config.add_search_field("issn_t", label: "ISSN") do |field|
      field.solr_local_parameters = {
        qf: "issn_t",
      }
    end

    config.add_search_field("call_number_t", label: "Call Number") do |field|
      field.include_in_advanced_search = true
      field.include_in_simple_select = false
      field.solr_local_parameters = {
        qf: "call_number_t",
      }
    end

    config.add_search_field("alma_mms_t", label: "Catalog Record ID") do |field|
      field.include_in_simple_select = false
      field.solr_local_parameters = {
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
    add_show_tools_partial(:ris, label: "RIS File", if: :render_ris_action?, modal: false, path: :ris_path)
    # Do not show endnotes for beta release
    config.show.document_actions.delete(:endnote)
    config.show.document_actions.delete(:citation)
    config.show.document_actions.delete(:sms) if Rails.configuration.features[:sms_document_action_disabled]
    config.show.document_actions.delete(:email) if Rails.configuration.features[:email_document_action_disabled]
  end

  def text_this_message_body(params)
    "#{params[:title]}\n" +
    "#{params[:location]}"
  end

  def browse_creator(args)
    creator = args[:document][args[:field]]
    base_path = helpers.base_path
    creator.map do |name|
      linked_subfields = name.split("|").first
      facet_query = view_context.send(:url_encode, (linked_subfields))
      newname = view_context.link_to(linked_subfields, base_path + "?f[creator_facet][]=#{facet_query}")
      plain_text_subfields = name.split("|").second
      creator = newname
      if plain_text_subfields.present?
        plain_text_subfields = plain_text_subfields
        creator = newname + " " + plain_text_subfields
      end
      creator
    end
  end

  def display_duration(args)
    args[:value]&.map { |v| v.scan(/([0-9]{2})/).join(":") }
  end

  ##
  # Render one index record (use as an ajax endpoint).
  # /
  def index_item
    (@response, doc) = fetch(params["id"])
    count = (params["document_counter"] || 0 rescue 0).to_i
    if (doc.nil?)
      # Ajax lookup failed once before already.
      doc = PrimoCentralDocument.new(
        "pnxId" => params["id"], "ajax" => false,
        "title" => params["id"]
      )
    end
    render "_document", layout: false, locals: { document: doc, document_counter: count }
  end

  ##
  # Overrides CatalogController.invalid_document_id_error
  #
  # Overridden so that we can use our own 404 error handling setup.
  def invalid_document_id_error(exception)
    respond_to do |format|
      format.xml  { render xml: error_info, status: 404 }
      format.json { render json: error_info, stautus: 404 }

      # default to HTML response, even for other non-HTML formats we don't
      # neccesarily know about, seems to be consistent with what Rails4 does
      # by default with uncaught ActiveRecord::RecordNotFound in production
      format.any do
        # use standard, possibly locally overridden, 404.html file. Even for
        # possibly non-html formats, this is consistent with what Rails does
        # on raising an ActiveRecord::RecordNotFound. Rails.root IS needed
        # for it to work under testing, without worrying about CWD.
        render "errors/not_found"
      end
    end
  end

  def raise_bad_range_limit(exception)
    flash[:notice] = exception.message
    redirect_to request.referrer || root_url
  end

  def purchase_order
    (@response, @document) = fetch(params["id"])
    render layout: false
  end

  def purchase_order_action
    (_, document) = fetch(params["id"])

    from = current_user&.email || params[:to]

    mail = PurchaseOrderMailer.purchase_order(document, { from: from, message: params[:message] }, url_options)
    if mail.respond_to? :deliver_now
      mail.deliver_now
    else
      mail.deliver
    end

    redirect_back(fallback_location: root_path)
  end

  # Overrides Blackligt::Catalog.sms_action.
  #
  # Passes extra chosen book details for sms text.
  #
  # SMS action (this will render the appropriate view on GET requests and
  # process the form and send the email on POST requests)
  def sms_action(documents)
    to = "#{params[:to].gsub(/[^\d]/, '')}@#{params[:carrier]}"
    documents[0][:sms] = documents[0].material_from_barcode(params[:barcode])

    mail = RecordMailer.sms_record(documents, { to: to }, url_options)

    if mail.respond_to? :deliver_now
      mail.deliver_now
    else
      mail.deliver
    end
  end

  # Overrides Blacklight::Catalog.validate_sms_params
  #
  # Adds validation of the location selection.
  def validate_sms_params
    # Short circuit the barcode validation.
    if !params.has_key? :barcode
      return super
    end

    if params[:barcode].blank?
      flash[:error] = "You must select a location."
    elsif !@documents.first.valid_barcode? params[:barcode]
      # Prevents abuse of feature for harrasment.
      flash[:error] = "An invalid location was selected."
    end

    super
  end

  private
    def catalog?
      self.class == CatalogController
    end

    def advanced_controller?
      self.class == AdvancedController
    end
end
