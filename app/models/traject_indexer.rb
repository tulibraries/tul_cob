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

# To have access to the traject marc format/carrier classifier
require "traject/macros/marc_format_classifier"
extend Traject::Macros::MarcFormats

# Include custom traject macros
require "traject/macros/custom"
extend Traject::Macros::Custom

settings do
  # type may be "binary", "xml", or "json"
  provide "marc_source.type", "xml"
  # set this to be non-negative if threshold should be enforced
  provide "solr_writer.max_skipped", -1
  # extend commit timeout
  provide "solr_writer.commit_timeout", 300
  provide "solr.url", solr_url
  provide "solr_writer.commit_on_close", "false"
end

to_field "id", extract_marc("001", first: true)
to_field "marc_display_raw", get_xml
to_field("text", extract_all_marc_values, &to_single_string)
to_field "language_facet", marc_languages("008[35-37]:041a:041d:")
to_field "language_display", marc_languages("008[35-37]:041a:041d:041e:041g:041j")
to_field("format", marc_formats, &normalize_format)

# Title fields

to_field "title_statement_display", extract_marc("245abcfgknps", alternate_script: false)
to_field "title_statement_vern_display", extract_marc("245abcfgknps", alternate_script: :only)
to_field "title_uniform_display", extract_marc("130adfklmnoprs:240adfklmnoprs:730ail", alternate_script: false)
to_field "title_uniform_vern_display", extract_marc("130adfklmnoprs:240adfklmnoprs:730ail", alternate_script: :only)
to_field "title_addl_display", extract_marc("210ab:246abfgnp:247abcdefgnp:740anp", alternate_script: false)
to_field "title_addl_vern_display", extract_marc("210ab:246abfgnp:247abcdefgnp:740anp", alternate_script: :only)

to_field "title_t", extract_marc("245a")
to_field "subtitle_t", extract_marc("245b")
to_field "title_statement_t", extract_marc("245abfgknps")
to_field "title_uniform_t", extract_marc("130adfklmnoprs:240adfklmnoprs:730abcdefgklmnopqrst")

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
to_field "title_added_entry_t", extract_marc(%W{
  700gklmnoprst
  710fgklmnopqrst
  711fgklnpst

                                             }.join(":"))
to_field "title_sort", marc_sortable_title

# Creator/contributor fields
to_field "creator_facet", extract_marc("100abcdejlmnopqrtu:110abcdelmnopt:111acdejlnopt:700abcdejlmnopqrtu:710abcdelmnopt:711acdejlnopt", trim_punctuation: true)
to_field "creator_display", extract_marc("100abcdejlmnopqrtu:110abcdelmnopt:111acdejlnopt", trim_punctuation: true, alternate_script: false)
to_field "contributor_display", extract_marc("700abcdejlmnopqrtu:710abcdelmnopt:711acdejlnopt", trim_punctuation: true, alternate_script: false)
to_field "creator_vern_display", extract_marc("100abcdejlmnopqrtu:110abcdelmnopt:111acdejlnopt", trim_punctuation: true, alternate_script: :only)
to_field "contributor_vern_display", extract_marc("700abcdejlmnopqrtu:710abcdelmnopt:711acdejlnopt", trim_punctuation: true, alternate_script: :only)

to_field "creator_t", extract_marc("245c:100abcdejlmnopqrtu:110abcdelmnopt:111acdejlnopt:700abcdejqu:710abcde:711acdej", trim_punctuation: true)
to_field "author_sort", marc_sortable_author

# Publication fields
# For the imprint, make sure to take RDA-style 264, second indicator = 1
to_field "imprint_display", extract_marc("260abcefg3:264|*0|abc3:264|*1|abc3:264|*2|abc3:264|*3|abc3", alternate_script: false)
to_field "imprint_vern_display", extract_marc("260abcefg3:264|*1|abc3", alternate_script: :only)
to_field "edition_display", extract_marc("250a:254a", trim_punctuation: true, alternate_script: false)
to_field "pub_date", extract_pub_date
to_field "date_copyright_display", extract_copyright

to_field "pub_location_t", extract_marc("260a:264a", trim_punctuation: true)
to_field "publisher_t", extract_marc("260b:264b", trim_punctuation: true)
to_field "pub_date_sort", marc_publication_date

# Physical characteristics fields -3xx
to_field "phys_desc_display", extract_marc("300abcefg3:340abcdefhijkmno")
to_field "duration_display", extract_marc("306a")
to_field "frequency_display", extract_marc("310ab:321ab")
to_field "sound_display", extract_marc("344abcdefgh")
to_field "digital_file_display", extract_marc("347abcdef")
to_field "form_work_display", extract_marc("380a")
to_field "performance_display", extract_marc("382abdenprst")
to_field "music_no_display", extract_marc("383abcde")

# Series fields
to_field "title_series_display", extract_marc("830av:490av:440anpv", alternate_script: false)
to_field "title_series_vern_display", extract_marc("830a:490a:440anp", alternate_script: :only)
# to_field "date_series", extract_marc("362a")

to_field "title_series_t", extract_marc("830av:490av:440anpv")

# Note fields
to_field "note_display", extract_marc("500a:508a:511a:515a:518a:521ab:530abcd:533abcdefmn:534pabcefklmnt:538aiu:546ab:550a:586a:588a")
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
to_field "subject_facet", extract_marc("600abcdefghklmnopqrstuxyz:610abcdefghklmnoprstuvxy:611acdefghjklnpqstuvxyz:630adefghklmnoprstvxyz:648axvyz:650abcdegvxyz:651aegvxyz:653a:654abcevyz:655abcvxyz:656akvxyz:657avxyz:690abcdegvxyz", separator: " — ", trim_punctuation: true)
to_field "subject_display", extract_marc("600abcdefghklmnopqrstuvxyz:610abcdefghklmnoprstuvxy:611acdefghjklnpqstuvxyz:630adefghklmnoprstvxyz:648axvyz:650abcdegvxyz:651aegvxyz:653a:654abcevyz:655abcvxyz:656akvxyz:657avxyz:690abcdegvxyz", separator: " — ", trim_punctuation: true)
to_field "subject_topic_facet", extract_marc("600abcdq:610ab:611a:630a:650a:653a:654ab:655ab")
to_field "subject_era_facet", extract_marc("648a:650y:651y:654y:655y:690y", trim_punctuation: true)
to_field "subject_region_facet", extract_marc("651a:650z:654z:655z", trim_punctuation: true)
to_field "genre_facet", extract_marc("600v:610v:611v:630v:648v:650v:651v:655av", trim_punctuation: true)

to_field "subject_t", extract_marc(%W(
  600#{ATOU}
  610#{ATOU}
  611#{ATOU}
  630#{ATOU}
  647acdg
  650abcde
  653a:654abcde
                                   ).join(":"))
to_field "subject_addl_t", extract_marc("600vwxyz:610vwxyz:611vwxyz:630vwxyz:647vwxyz:648avwxyz:650vwxyz:651aegvwxyz:654vwxyz:655abcvxyz:656akvxyz:657avxyz:690abcdegvwxyz")

# Location fields
to_field "call_number_display", extract_marc("HLDhi")
to_field "call_number_alt_display", extract_marc("ITMjk")
to_field "library_facet", extract_library

# Call Number fields
to_field "lc_callnum_display", extract_marc("050ab", first: true)
to_field("lc_1letter_facet", extract_marc("050ab", first: true, translation_map: "callnumber_map"), &first_letters_only)
to_field("lc_alpha_facet", extract_marc("050a", first: true), &normalize_lc_alpha)
to_field "lc_b4cutter_facet", extract_marc("050a", first: true)

# URL Fields
to_field "url_more_links_display", extract_url_more_links
to_field "electronic_resource_display", extract_electronic_resource

# Availability
to_field "availability_facet", extract_availability
to_field "location_display", extract_marc("HLDc")

# Identifier fields
to_field("isbn_display",  extract_marc("020a", separator: nil), &normalize_isbn)
to_field("issn_display", extract_marc("022a", separator: nil), &normalize_issn)
to_field("lccn_display", extract_marc("010ab", separator: nil), &normalize_lccn)
to_field "pub_no_display", extract_marc("028ab")
to_field "sudoc_display", extract_marc("086|0*|a")
to_field "diamond_id_display", extract_marc("907a")
to_field "gpo_display", extract_marc("074a")
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
