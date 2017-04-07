$:.unshift './config'
require "traject"
require "blacklight/marc"

class MarcIndexer < Blacklight::Marc::Indexer
  # this mixin defines lambda factory method get_format for legacy marc formats
  include Blacklight::Marc::Indexer::Formats

  def initialize
    super

    settings do
      # type may be 'binary', 'xml', or 'json'
      provide "marc_source.type", "xml"
      # set this to be non-negative if threshold should be enforced
      provide 'solr_writer.max_skipped', -1
      #provide 'solr.update_url', 'http://localhost:8983/solr/blacklight-core/update'
      provide "solr_writer.commit_on_close", "false"
    end

    #to_field 'id', trim(extract_marc("001"), :first => true)
    to_field("id") do |rec, acc|
      if (rec['001'])
        id = rec['001'].value
      else
        id = rec['907']['a'][1..-1]
      end
      acc << id
    end
    to_field 'marc_display', get_xml
    to_field "text", extract_all_marc_values do |r, acc|
      acc.replace [acc.join(' ')] # turn it into a single string
    end

    to_field "language_facet", marc_languages("008[35-37]:041a:041d:041e:041g:041j") #NOTE: added egj
    to_field "format", get_format
    to_field "isbn_t",  extract_marc('020a', :separator=>nil) do |rec, acc|
         orig = acc.dup
         acc.map!{|x| StdNum::ISBN.allNormalizedValues(x)}
         acc << orig
         acc.flatten!
         acc.uniq!
    end

    to_field 'material_type_display', extract_marc('300a', :trim_punctuation => true)

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
    to_field 'subject_topic_facet', extract_marc("600abcdq:610ab:611ab:630aa:650aa:653aa:654ab:655ab", :trim_punctuation => true)
    to_field 'subject_era_facet',  extract_marc("650y:651y:654y:655y", :trim_punctuation => true)
    to_field 'subject_geo_facet',  extract_marc("651a:650z",:trim_punctuation => true )

    # Publication fields
    to_field 'published_display', extract_marc('260a', :trim_punctuation => true, :alternate_script=>false)
    to_field 'published_vern_display', extract_marc('260a', :trim_punctuation => true, :alternate_script=>:only)

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

    #Control number - set flag to identify no control numbers
    to_field 'control_number_display', extract_marc('907a', :first=>true) do |_, acc|
      acc << 'NO CONTROL NUMBER' if acc.empty?
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






    #new solr fields from emitone
    to_field 'title_statement', extract_marc('245abcfgknps')
    to_field 'title', extract_marc('245a', :trim_punctuation => true)
    to_field 'subtitle', extract_marc('245b', :trim_punctuation => true)
    to_field 'title_uniform', extract_marc('130adfklmnoprs:240adfklmnoprs')
    to_field 'title_addl', extract_marc('210ab:246abfgnp:740anp')
    to_field 'creator', extract_marc('100abcdeq:110abcde:111acdej:700abcdeq:710abcde:711acdej', :trim_punctuation => true)
    to_field 'imprint', extract_marc('260abcefg3:264abc3')
    to_field 'edition', extract_marc('250a')

    to_field 'pub_date' do |rec, acc|   #, extract_marc('260c:264c')
      # fairly aggressive prune to get pub dates down to a 4 digit year
      rec.fields(['260','264']).each do |field|
        acc << field['c'].gsub(/[^0-9,.]/, '').gsub(/[[:punct:]]/, '')[0..3].strip  unless field['c'].nil?
      end
    end

    to_field 'pub_location', extract_marc('260a:264a', :trim_punctuation => true)
    to_field 'publisher', extract_marc('260b:264b', :trim_punctuation => true)
    to_field 'phys_desc', extract_marc('300abcefg3')
    to_field 'title_series', extract_marc('830av:490av:440anpv')
    to_field 'volume', extract_marc('830v:490v:440v')
    to_field 'note', extract_marc('500a:502abcdgo:508a:511a:518a:530abcd:533abcdefmn:534pabcefklmnt:538aiu')
    to_field 'note_with', extract_marc('501a')
    to_field 'note_biblio', extract_marc('504a')
    to_field 'note_toc', extract_marc('505agrt')
    to_field 'note_restrictions', extract_marc('506abcde')
    to_field 'note_references', extract_marc('510abc')
    to_field 'note_summary', extract_marc('520ab')
    to_field 'note_cite', extract_marc('524a')
    to_field 'note_terms', extract_marc('540a')
    to_field 'note_bio', extract_marc('545abu')
    to_field 'note_finding_aid', extract_marc('555abcdu3')
    to_field 'note_custodial', extract_marc('561a')
    to_field 'note_binding', extract_marc('563a')
    to_field 'note_related', extract_marc('580a')
    to_field 'note_accruals', extract_marc('584a')
    to_field 'note_local', extract_marc('590a')
    to_field 'subject', extract_marc('600abcdefghklmnopqrstuxyz:610abcdefghklmnoprstuvxy:611acdefghjklnpqstuvxyz:630adefghklmnoprstvxyz:648axvyz:650abcdegvxyz:651aegvxyz:653a:690abcdegvxyz', :trim_punctuation => true)
    to_field 'subject_topic', extract_marc('600abcdq:610ab:611a:630a:650a:653a:654ab:655ab')
    to_field 'subject_era', extract_marc('648a:650y:651y:654y:655y:690y', :trim_punctuation => true)
    to_field 'subject_region', extract_marc('651a:650z:654z:655z', :trim_punctuation => true)
    to_field 'genre', extract_marc('600v:610v:611v:630v:648v:650v:651v:655av', :trim_punctuation => true)
    to_field 'call_number', extract_marc('852hi')

    to_field 'library' do |rec, acc|   #extract_marc('852b')
      rec.fields('852').each do |field|
        # Strip the values and downcase for indexing into locations.yml
        acc << field['b'].strip.downcase unless field['b'].nil?
      end
    end

    to_field 'url', extract_marc(%W(856#{ATOZ}))  #Chad and Emily are working on this
    to_field 'isbn', extract_marc('020a')
    to_field 'issn', extract_marc('022a')
    to_field 'govdoc', extract_marc('086az')
  end
end

