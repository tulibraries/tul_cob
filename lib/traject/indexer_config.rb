# frozen_string_literal: true

$:.unshift "./config"
$:.unshift "./lib"
require "yaml"
solr_config = YAML.load_file("config/blacklight.yml")[(ENV["RAILS_ENV"] || "development")]
solr_url = ERB.new(solr_config["url"]).result
# A sample traject configuration, save as say `traject_config.rb`, then
# run `traject -c traject_config.rb marc_file.marc` to index to
# solr specified in config file, according to rules specified in
# config file


# To have access to various built-in logic
# for pulling things out of MARC21, like `marc_languages`
require "traject/macros/marc21_semantics"
extend  Traject::Macros::Marc21Semantics

# Overrides the trim_punctuation method to remove periods preceded by parentheses
require "traject/macros/custom_marc21"


# To have access to the traject marc format/carrier classifier
require "traject/macros/marc_format_classifier"
extend Traject::Macros::MarcFormats

# Include custom traject macros
# include unicode normalize for thread safety
require "unicode_normalize/normalize.rb"
require "traject/macros/custom"
extend Traject::Macros::Custom

settings do
  # type may be "binary", "xml", or "json"
  provide "marc_source.type", "xml"
  # set this to be non-negative if threshold should be enforced
  provide "solr_writer.max_skipped", -1
  # extend commit timeout
  provide "solr_writer.commit_timeout", (15 * 60)
  provide "solr.url", solr_url
  provide "solr_writer.commit_on_close", "false"
end

each_record do |record, context|
  if record.fields("245").any? { |f| f["a"].to_s.downcase.include? "host bibliographic record for boundwith item barcode" }
    context.skip!("Skipping Boundwith host record")
  end
end

to_field "id", extract_marc("001", first: true)
to_field "marc_display_raw", get_xml
to_field("text", extract_all_marc_values, &to_single_string)
to_field "language_facet", extract_lang("008[35-37]:041a:041d:041e:041g:041j")
to_field "language_display", extract_lang("008[35-37]:041a:041d:041e:041g:041j")
to_field("format", marc_formats, &normalize_format)

# Title fields

to_field "title_statement_display", extract_marc("245abcfgknps", alternate_script: false)
to_field "title_truncated_display", extract_marc("245abcfgknps", alternate_script: false), &truncate(300)
to_field "title_statement_vern_display", extract_marc("245abcfgknps", alternate_script: :only)
to_field "title_uniform_display", extract_marc("130adfklmnoprs:240adfklmnoprs:730ail", alternate_script: false)
to_field "title_uniform_vern_display", extract_marc("130adfklmnoprs:240adfklmnoprs:730ail", alternate_script: :only)
to_field "title_addl_display", extract_marc("210ab:246iabfgnp:247abcdefgnp:740anp", alternate_script: false)
to_field "title_addl_vern_display", extract_marc("210ab:246abfgnp:247abcdefgnp:740anp", alternate_script: :only)

to_field "title_t", extract_marc_with_flank("245a")
to_field "subtitle_t", extract_marc_with_flank("245b")
to_field "title_statement_t", extract_marc_with_flank("245abfgknps")
to_field "title_uniform_t", extract_marc_with_flank("130adfklmnoprs:240adfklmnoprs:730abcdefgklmnopqrst")

to_field "work_access_point", extract_work_access_point

ATOZ = ("a".."z").to_a.join("")
ATOU = ("a".."u").to_a.join("")
to_field "title_addl_t",
  extract_marc(%W{
    210ab
    222ab
    242abnp
    243abcdefgklmnopqrs
    246abcdefgnp
    247abcdefgnp
    740anp
               }.join(":"))
to_field "title_added_entry_t", extract_marc_with_flank(%W{
  700gklmnoprst
  710fgklmnopqrst
  711fgklnpst

                                             }.join(":"))
to_field "title_sort", extract_marc("245abcfgknps", alternate_script: false, first: true)

# Creator/contributor fields
to_field "creator_t", extract_marc_with_flank("245c:100abcdejlmnopqrtu:110abcdelmnopt:111acdejlnopt:700abcdejqu:710abcde:711acdej", trim_punctuation: true)
to_field "creator_facet", extract_marc("100abcdq:110abcd:111ancdj:700abcdq:710abcd:711ancdj", trim_punctuation: true)
to_field "creator_display", extract_creator
to_field "contributor_display", extract_contributor
to_field "creator_vern_display", extract_creator_vern
to_field "contributor_vern_display", extract_contributor_vern

to_field "author_sort", extract_marc("100abcdejlmnopqrtu:110abcdelmnopt:111acdejlnopt", trim_punctuation: true, first: true)

# Publication fields
# For the imprint, make sure to take RDA-style 264, second indicator = 1
to_field "imprint_display", extract_marc("260abcefg3:264|*0|abc3:264|*1|abc3:264|*2|abc3:264|*3|abc3", alternate_script: false)
to_field "imprint_vern_display", extract_marc("260abcefg3:264|*1|abc3", alternate_script: :only)
to_field "edition_display", extract_marc("250a:254a", trim_punctuation: true, alternate_script: false)
to_field "pub_date", extract_pub_date
to_field "date_copyright_display", extract_copyright

to_field "pub_location_t", extract_marc_with_flank("260a:264a", trim_punctuation: true)
to_field "publisher_t", extract_marc_with_flank("260b:264b", trim_punctuation: true)
to_field "pub_date_sort", marc_publication_date
to_field "pub_date_tdt", extract_pub_datetime

# Physical characteristics fields -3xx
to_field "phys_desc_display", extract_marc("300abcefg3:340abcdefhijkmno")
to_field "duration_display", extract_marc("306a")
to_field "frequency_display", extract_marc("310ab:321ab")
to_field "sound_display", extract_marc("344abcdefgh")
to_field "digital_file_display", extract_marc("347abcdef")
to_field "form_work_display", extract_marc("380a")
to_field "performance_display", extract_marc("382abdenprst")
to_field "music_no_display", extract_marc("383abcde")
to_field "video_file_display", extract_marc("346ab")
to_field "music_format_display", extract_marc("348a")
to_field "music_key_display", extract_marc("384a")
to_field "audience_display", extract_marc("385am")
to_field "creator_group_display", extract_marc("386aim")
to_field "date_period_display", extract_marc("388a")
to_field "collection_display", extract_marc("973at")
to_field "collection_area_display", extract_marc("974at")

# Series fields
to_field "title_series_display", extract_marc("830av:490av:440anpv:800abcdefghjklmnopqrstuv:810abcdeghklmnoprstuv:811acdefghjklnpqstuv", alternate_script: false)
to_field "title_series_vern_display", extract_marc("830av:490av:440anpv:800abcdefghjklmnopqrstuv:810abcdeghklmnoprstuv:811acdefghjklnpqstuv", alternate_script: :only)
# to_field "date_series", extract_marc("362a")

to_field "title_series_t", extract_marc_with_flank("830av:490av:440anpv")

# Note fields
to_field "note_display", extract_marc("500a:508a:511a:515a:518a:521ab:525a:530abcd:533abcdefmn:534pabcefklmnt:538aiu:546ab:550a:586a:588a")
to_field "note_with_display", extract_marc("501a")
to_field "note_diss_display", extract_marc("502abcdgo")
to_field "note_biblio_display", extract_marc("504a")
to_field "note_toc_display", extract_marc("505agrt")
to_field "note_restrictions_display", extract_marc("506abcde")
to_field "note_references_display", extract_marc("510abc")
to_field "note_summary_display", extract_marc("520ab")
to_field "note_cite_display", extract_marc("524a")
# Note Copyright should not display if ind1 = 0.  This ensures that it works if the value is unassigned or 1
to_field "note_copyright_display", extract_marc("540a:542|1*|abcdefghijklmnopqr3:542| *|abcdefghijklmnopqr3")
to_field "note_bio_display", extract_marc("545abu")
to_field "note_finding_aid_display", extract_marc("555abcdu3")
to_field "note_custodial_display", extract_marc("561a")
to_field "note_binding_display", extract_marc("563a")
to_field "note_related_display", extract_marc("580a")
to_field "note_accruals_display", extract_marc("584a")
to_field "note_local_display", extract_marc("590a")

# Subject fields
to_field "subject_facet", extract_subject_display
to_field "subject_display", extract_subject_display
to_field "subject_topic_facet", extract_subject_topic_facet
to_field "subject_era_facet", extract_marc("648a:650y:651y:654y:655y:690y:647y", trim_punctuation: true)
to_field "subject_region_facet", marc_geo_facet
to_field "genre_facet", extract_genre

to_field "subject_t", extract_marc_with_flank(%W(
  600#{ATOU}
  610#{ATOU}
  611#{ATOU}
  630#{ATOU}
  647acdg
  650abcde
  653a:654abcde
                                   ).join(":"))
to_field "subject_addl_t", extract_marc_with_flank("600vwxyz:610vwxyz:611vwxyz:630vwxyz:647vwxyz:648avwxyz:650vwxyz:651aegvwxyz:654vwxyz:655abcvxyz:656akvxyz:657avxyz:690abcdegvwxyz")

# Location fields
to_field "call_number_display", extract_marc("HLDhi")
to_field "call_number_t", extract_marc_with_flank("HLDhi")
to_field "call_number_alt_display", extract_marc("ITMjk")
to_field "call_number_alt_t", extract_marc_with_flank("ITMjk")
to_field "library_facet", extract_library
to_field "library_location_display", extract_library_shelf_call_number

# Call Number fields
to_field "lc_callnum_display", extract_marc("050ab", first: true)
to_field("lc_1letter_facet", extract_marc("050ab", first: true, translation_map: "callnumber_map"), &first_letters_only)
to_field("lc_alpha_facet", extract_marc("050a", first: true), &normalize_lc_alpha)
to_field "lc_b4cutter_facet", extract_marc("050a", first: true)

# URL Fields
to_field "url_more_links_display", extract_url_more_links
to_field("electronic_resource_display", extract_electronic_resource, &sort_electronic_resource!)
to_field "url_finding_aid_display", extract_url_finding_aid

# Availability
to_field "availability_facet", extract_availability
to_field "location_display", extract_marc("HLDbc")
to_field "holdings_with_no_items_display", extract_holdings_with_no_items
to_field "suppress_items_b", suppress_items
to_field "holdings_summary_display", extract_holdings_summary

# Identifier fields
to_field("isbn_display",  extract_marc("020a", separator: nil), &normalize_isbn)
to_field("alt_isbn_display",  extract_marc("020z:776z", separator: nil), &normalize_isbn)
to_field("issn_display", extract_marc("022a", separator: nil), &normalize_issn)
to_field("alt_issn_display", extract_marc("022lz:776x", separator: nil), &normalize_issn)
to_field("lccn_display", extract_marc("010ab", separator: nil), &normalize_lccn)
to_field "pub_no_display", extract_marc("028ab")
to_field "sudoc_display", extract_marc("086|0*|a")
to_field "diamond_id_display", extract_marc("907a")
to_field "gpo_display", extract_marc("074a")
to_field "oclc_number_display", extract_oclc_number
to_field "alma_mms_display", extract_marc("001")

# Preceding Entry fields
to_field "continues_display", extract_marc("780|00|iabdghkmnopqrstuxyz3:780|02|iabdghkmnopqrstuxyz3", trim_punctuation: true)
to_field "continues_in_part_display", extract_marc("780|01|iabdghkmnopqrstuxyz3:780|03|iabdghkmnopqrstuxyz3", trim_punctuation: true)
to_field "formed_from_display", extract_marc("780|04|iabdghkmnopqrstuxyz3", trim_punctuation: true)
to_field "absorbed_display", extract_marc("780|05|iabdghkmnopqrstuxyz3", trim_punctuation: true)
to_field "absorbed_in_part_display", extract_marc("780|06|iabdghkmnopqrstuxyz3", trim_punctuation: true)
to_field "separated_from_display", extract_marc("780|07|iabdghkmnopqrstuxyz3", trim_punctuation: true)

# Succeeding Entry fields
to_field "continued_by_display", extract_marc("785|00|iabdghkmnopqrstuxyz3:785|02|iabdghkmnopqrstuxyz3", trim_punctuation: true)
to_field "continued_in_part_by_display", extract_marc("785|01|iabdghkmnopqrstuxyz3:785|03|iabdghkmnopqrstuxyz3", trim_punctuation: true)
to_field "absorbed_by_display", extract_marc("785|04|iabdghkmnopqrstuxyz3", trim_punctuation: true)
to_field "absorbed_in_part_by_display", extract_marc("785|05|iabdghkmnopqrstuxyz3", trim_punctuation: true)
to_field "split_into_display", extract_marc("785|06|iabdghkmnopqrstuxyz3", trim_punctuation: true)
to_field "merged_to_form_display", extract_marc("785|07|iabdghkmnopqrstuxyz3", trim_punctuation: true)
to_field "changed_back_to_display", extract_marc("785|08|iabdghkmnopqrstuxyz3", trim_punctuation: true)


# Boost records with holdings from specific libraries
# we actually want to negative boost specific libraries, but that is not possible
# so we are going to boost everything except the less relevant libraries
to_field "library_based_boost_t", library_based_boost

to_field "bound_with_ids", extract_marc("ADFa")
