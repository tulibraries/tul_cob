$:.unshift './config'
require 'yaml'
solr_config = YAML.load_file("config/blacklight.yml")[(ENV["RAILS_ENV"] || "development")]
solr_url = ERB.new(solr_config['url']).result
# A sample traject configuration, save as say `traject_config.rb`, then
# run `traject -c traject_config.rb marc_file.marc` to index to
# solr specified in config file, according to rules specified in
# config file


# To have access to various built-in logic
# for pulling things out of MARC21, like `marc_languages`
require 'traject/macros/marc21_semantics'
extend  Traject::Macros::Marc21Semantics

# To have access to the traject marc format/carrier classifier
require 'traject/macros/marc_format_classifier'
extend Traject::Macros::MarcFormats

require 'library_stdnums'


# Copied from https://github.com/projectblacklight/blacklight-marc/blob/master/lib/blacklight/marc/indexer.rb#L18-L19
ATOZ = ('a'..'z').to_a.join('')
ATOU = ('a'..'u').to_a.join('')

def get_xml options={}
  lambda do |record, accumulator|
    accumulator << MARC::FastXMLWriter.encode(record)
  end
end

def four_digit_year(field)
  field.gsub(/[^0-9,.]/, '').gsub(/[[:punct:]]/, '')[0..3].strip unless field.nil?
end

settings do
  # type may be 'binary', 'xml', or 'json'
  provide "marc_source.type", "xml"
  # set this to be non-negative if threshold should be enforced
  provide 'solr_writer.max_skipped', -1
  # extend commit timeout
  provide 'solr_writer.commit_timeout', 300
  provide 'solr.url', solr_url
  provide "solr_writer.commit_on_close", "true"
end

to_field "id", extract_marc("001", :first => true)
to_field 'marc_display', get_xml
to_field "text", extract_all_marc_values do |r, acc|
  acc.replace [acc.join(' ')] # turn it into a single string
end

to_field "language_facet", marc_languages("008[35-37]:041a:041d:")
to_field "language_display", marc_languages("008[35-37]:041a:041d:041e:041g:041j")

to_field "format", marc_formats

to_field "isbn_t",  extract_marc('020a', :separator=>nil) do |rec, acc|
     orig = acc.dup
     acc.map!{|x| StdNum::ISBN.allNormalizedValues(x)}
     acc << orig
     acc.flatten!
     acc.uniq!
end

#to_field 'material_type_display', extract_marc('300a', :trim_punctuation => true)

# Title fields
#    primary title

to_field 'title_t', extract_marc('245a')
to_field 'title_display', extract_marc('245a', :trim_punctuation => true, :alternate_script=>false) do |r, acc|
  acc.replace [acc.join(' ')] # turn it into a single string
end

to_field 'title_vern_display', extract_marc('245a', :trim_punctuation => true, :alternate_script=>:only)

#    subtitle

to_field 'subtitle_t', extract_marc('245b')
to_field 'subtitle_display', extract_marc('245b', :trim_punctuation => true, :alternate_script=>false)do |r, acc|
  acc.replace [acc.join(' ')] # turn it into a single string
end
to_field 'subtitle_vern_display', extract_marc('245b', :trim_punctuation => true, :alternate_script=>:only)

#    additional title fields
to_field 'title_addl_t',
  extract_marc(%W{
    245abnps
    130#{ATOZ}
    240abcdefgklmnopqrs
    210ab
    222ab
    242abnp
    243abcdefgklmnopqrs
    246abcdefgnp
    247abcdefgnp
  }.join(':'))

to_field 'title_added_entry_t', extract_marc(%W{
  700gklmnoprst
  710fgklmnopqrst
  711fgklnpst
  730abcdefgklmnopqrst
  740anp
}.join(':'))

to_field 'title_series_t', extract_marc("440anpv:490av")

to_field 'title_sort', marc_sortable_title

# Author fields

to_field 'author_t', extract_marc("100abcegqu:110abcdegnu:111acdegjnqu")
to_field 'author_addl_t', extract_marc("700abcegqu:710abcdegnu:711acdegjnqu")
to_field 'author_display', extract_marc("100abcdq:110#{ATOZ}:111#{ATOZ}", :alternate_script=>false)
to_field 'author_vern_display', extract_marc("100abcdq:110#{ATOZ}:111#{ATOZ}", :alternate_script=>:only)

# JSTOR isn't an author. Try to not use it as one
to_field 'author_sort', marc_sortable_author

# Subject fields
to_field 'subject_t', extract_marc(%W(
  600#{ATOU}
  610#{ATOU}
  611#{ATOU}
  630#{ATOU}
  650abcde
  651ae
  653a:654abcde:655abc
).join(':'))
to_field 'subject_addl_t', extract_marc("600vwxyz:610vwxyz:611vwxyz:630vwxyz:650vwxyz:651vwxyz:654vwxyz:655vwxyz")
#to_field 'subject_topic_facet', extract_marc("600abcdq:610ab:611ab:630aa:650aa:653aa:654ab:655ab", :trim_punctuation => true)
#to_field 'subject_era_facet',  extract_marc("650y:651y:654y:655y", :trim_punctuation => true)
#to_field 'subject_geo_facet',  extract_marc("651a:650z",:trim_punctuation => true )

# Publication fields
#to_field 'published_display', extract_marc('260a', :trim_punctuation => true, :alternate_script=>false)
#to_field 'published_vern_display', extract_marc('260a', :trim_punctuation => true, :alternate_script=>:only)

#does marc_publication_date guarantee single value?
to_field 'pub_date_sort', marc_publication_date

# Call Number fields
to_field 'lc_callnum_display', extract_marc('050ab', :first => true)
to_field 'lc_1letter_facet', extract_marc('050ab', :first=>true, :translation_map=>'callnumber_map') do |rec, acc|
  # Just get the first letter to send to the translation map
  acc.map!{|x| x[0]}
end

alpha_pat = /\A([A-Z]{1,3})\d.*\Z/
to_field 'lc_alpha_facet', extract_marc('050a', :first=>true) do |rec, acc|
  acc.map! do |x|
    (m = alpha_pat.match(x)) ? m[1] : nil
  end
  acc.compact! # eliminate nils
end

to_field 'lc_b4cutter_facet', extract_marc('050a', :first=>true)

# URL Fields

notfulltext = /abstract|description|sample text|table of contents|/i

to_field('url_fulltext_display') do |rec, acc|
  rec.fields('856').each do |f|
    case f.indicator2
    when '0'
      f.find_all{|sf| sf.code == 'u'}.each do |url|
        acc << url.value
      end
    when '2'
      # do nothing
    else
      z3 = [f['z'], f['3']].join(' ')
      unless notfulltext.match(z3)
        acc << f['u'] unless f['u'].nil?
      end
    end
  end
end

# Very similar to url_fulltext_display. Should DRY up.
to_field 'url_suppl_display' do |rec, acc|
  rec.fields('856').each do |f|
    case f.indicator2
    when '2'
      f.find_all{|sf| sf.code == 'u'}.each do |url|
        acc << url.value
      end
    when '0'
      # do nothing
    else
      z3 = [f['z'], f['3']].join(' ')
      if notfulltext.match(z3)
        acc << f['u'] unless f['u'].nil?
      end
    end
  end
end


    to_field 'location_facet' do |rec, acc|
      rec.fields('945').each do |field|
        #Strip the values, as many come in with space padding
        acc << field['l'].strip unless field['l'].nil?
      end
    end

    # This should probably not be a display
    to_field 'location_display' do |rec, acc|
      rec.fields('945').each do |field|
        acc << field['l'].strip unless field['l'].nil?
      end
      acc.replace [acc.join(",")]
    end



    #new solr fields for TUL search

    #Title fields

    to_field 'title_statement_display', extract_marc('245abcfgknps', :alternate_script=>false)
    to_field 'title_statement_vern_display', extract_marc('245abcfgknps', :alternate_script=>:only)
    to_field 'title_uniform_display', extract_marc('130adfklmnoprs:240adfklmnoprs:730ail', :alternate_script=>false)
    to_field 'title_uniform_vern_display', extract_marc('130adfklmnoprs:240adfklmnoprs:730ail', :alternate_script=>:only)
    to_field 'title_addl_display', extract_marc('210ab:246abfgnp:247abcdefgnp:740anp', :alternate_script=>false)
    to_field 'title_addl_vern_display', extract_marc('210ab:246abfgnp:247abcdefgnp:740anp', :alternate_script=>:only)

    #Creator/contributor fields

    to_field 'creator_display', extract_marc('100abcdejlmnopqrtu:110abcdelmnopt:111acdejlnopt:700abcdejlmnopqrtu:710abcdelmnopt:711acdejlnopt', :trim_punctuation => true, :alternate_script=>false)
    to_field 'creator_vern_display', extract_marc('100abcdejlmnopqrtu:110abcdelmnopt:111acdejlnopt:700abcdejlmnopqrtu:710abcdelmnopt:711acdejlnopt', :trim_punctuation => true, :alternate_script=>:only)
    #creator_facet?

    #publication fields
    # For the imprint, make sure to take RDA-style 264, second
    # indicator = 1
    to_field 'imprint_display', extract_marc('260abcefg3:264|*1|abc3', :alternate_script=>false)
    to_field 'imprint_vern_display', extract_marc('260abcefg3:264|*1|abc3', :alternate_script=>:only)
    to_field 'edition_display', extract_marc('250a:254a', :trim_punctuation => true, :alternate_script=>false)
    to_field 'pub_location_t', extract_marc('260a:264a', :trim_punctuation => true)
    to_field 'publisher_t', extract_marc('260b:264b', :trim_punctuation => true)

    to_field 'pub_date' do |rec, acc|
      rec.fields(['260']).each do |field|
        acc << four_digit_year(field['c']) unless field['c'].nil?
      end

      rec.fields(['264']).each do |field|
        acc << four_digit_year(field['c']) unless field['c'].nil? || field.indicator2 == '4'
      end
    end

    to_field 'date_copyright_display' do |rec, acc|
      rec.fields(['264']).each do |field|
        acc << four_digit_year(field['c'])  if field.indicator2 == '4'
      end
    end

    # to_field 'carto_data_display', extract_marc('', :trim_punctuation => true)

    #physical characteristics fields -3xx

    to_field 'phys_desc_display', extract_marc('300abcefg3:340abcdefhijkmno')
    to_field 'duration_display', extract_marc('306a')
    to_field 'frequency_display', extract_marc('310ab:321ab')
    to_field 'sound_display', extract_marc('344abcdefgh')
    to_field 'digital_file_display', extract_marc('347abcdef')
    to_field 'form_work_display', extract_marc('380a')
    to_field 'performance_display', extract_marc('382abdenprst')
    to_field 'music_no_display', extract_marc('383abcde')

    #series fields

    to_field 'title_series_display', extract_marc('830av:490av:440anpv', :alternate_script=>false)
    to_field 'title_series_vern_display', extract_marc('830a:490a:440anp', :alternate_script=>:only)
    # to_field 'date_series', extract_marc('362a')
    to_field 'volume_series_display', extract_marc('830v:490v:440v')


    #note fields

    to_field 'note_display', extract_marc('500a:508a:511a:515a:518a:521ab:530abcd:533abcdefmn:534pabcefklmnt:538aiu:546ab:550a:586a:588a')
    to_field 'note_with_display', extract_marc('501a')
    to_field 'note_diss_display', extract_marc('502abcdgo')
    to_field 'note_biblio_display', extract_marc('504a')
    to_field 'note_toc_display', extract_marc('505agrt')
    to_field 'note_restrictions_display', extract_marc('506abcde')
    to_field 'note_references_display', extract_marc('510abc')
    to_field 'note_summary_display', extract_marc('520ab')
    to_field 'note_cite_display', extract_marc('524a')
    # Note Copyright should not display if ind1 = 0.  This ensures that it works if the value is unassigned or 1
    to_field 'note_copyright_display', extract_marc('540a:542|1*|abcdefghijklmnopqr3:542| *|abcdefghijklmnopqr3')
    to_field 'note_bio_display', extract_marc('545abu')
    to_field 'note_finding_aid_display', extract_marc('555abcdu3')
    to_field 'note_custodial_display', extract_marc('561a')
    to_field 'note_binding_display', extract_marc('563a')
    to_field 'note_related_display', extract_marc('580a')
    to_field 'note_accruals_display', extract_marc('584a')
    to_field 'note_local_display', extract_marc('590a')

    #subject fields
    #Note need to improve the subjects
    to_field 'subject_display', extract_marc('600abcdefghklmnopqrstuxyz:610abcdefghklmnoprstuvxy:611acdefghjklnpqstuvxyz:630adefghklmnoprstvxyz:648axvyz:650abcdegvxyz:651aegvxyz:653a:690abcdegvxyz', :trim_punctuation => true)
    to_field 'subject_topic_facet', extract_marc('600abcdq:610ab:611a:630a:650a:653a:654ab:655ab')
    to_field 'subject_era_facet', extract_marc('648a:650y:651y:654y:655y:690y', :trim_punctuation => true)
    to_field 'subject_region_facet', extract_marc('651a:650z:654z:655z', :trim_punctuation => true)
    to_field 'genre_facet', extract_marc('600v:610v:611v:630v:648v:650v:651v:655av', :trim_punctuation => true)

    #location fields

    to_field 'call_number_display', extract_marc('852hi')

    to_field 'library_display' do |rec, acc|   #extract_marc('852b')
      rec.fields('852').each do |field|
        # Strip the values and downcase for indexing into locations.yml
        acc << field['b'].strip.downcase unless field['b'].nil?
      end
    end

    to_field 'url', extract_marc(%W(856#{ATOZ}))  #Chad and Emily are working on this

    #Identifier fields

    #to_field 'isbn_display', extract_marc('020aq')
    to_field 'isbn_display', extract_marc('020a')
    to_field 'issn_display', extract_marc('022a')
    to_field 'pub_no_display', extract_marc('028ab')
    to_field 'sudoc_display', extract_marc('086|0*|a')
    to_field 'diamond_id_display', extract_marc('907a')
    to_field 'lccn_display', extract_marc('010ab')
    to_field 'gpo_display', extract_marc('074a')
    to_field 'alma_mms_display', extract_marc('001')


    #Preceding Entry fields
    to_field 'continues_display', extract_marc('780|00|iabdghkmnopqrstuxyz3:780|02|iabdghkmnopqrstuxyz3', trim_punctuation: true)
    to_field 'continues_in_part_display', extract_marc('780|01|iabdghkmnopqrstuxyz3:780|03|iabdghkmnopqrstuxyz3', trim_punctuation: true)
    to_field 'formed_from_display', extract_marc('780|04|iabdghkmnopqrstuxyz3', trim_punctuation: true)
    to_field 'absorbed_display', extract_marc('780|05|iabdghkmnopqrstuxyz3', trim_punctuation: true)
    to_field 'absorbed_in_part_display', extract_marc('780|06|iabdghkmnopqrstuxyz3', trim_punctuation: true)
    to_field 'separated_from_display', extract_marc('780|07|iabdghkmnopqrstuxyz3', trim_punctuation: true)

    #Succeeding Entry fields
    to_field 'continued_by_display', extract_marc('785|00|iabdghkmnopqrstuxyz3:785|02|iabdghkmnopqrstuxyz3', trim_punctuation: true)
    to_field 'continued_in_part_by_display', extract_marc('785|01|iabdghkmnopqrstuxyz3:785|03|iabdghkmnopqrstuxyz3', trim_punctuation: true)
    to_field 'absorbed_by_display', extract_marc('785|04|iabdghkmnopqrstuxyz3', trim_punctuation: true)
    to_field 'absorbed_in_part_by_display', extract_marc('785|05|iabdghkmnopqrstuxyz3', trim_punctuation: true)
    to_field 'split_into_display', extract_marc('785|06|iabdghkmnopqrstuxyz3', trim_punctuation: true)
    to_field 'merged_to_form_display', extract_marc('785|07|iabdghkmnopqrstuxyz3', trim_punctuation: true)
    to_field 'changed_back_to_display', extract_marc('785|08|iabdghkmnopqrstuxyz3', trim_punctuation: true)
