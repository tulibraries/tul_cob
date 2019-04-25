# frozen_string_literal: true

require "library_stdnums"
require "active_support/core_ext/object/blank"
require "time"

# A set of custom traject macros (extractors and normalizers) used by the
module Traject
  module Macros
    module Custom
      ARCHIVE_IT_LINKS = "archive-it.org/collections/"
      NOT_FULL_TEXT = /book review|publisher description|sample text|View cover art|Image|cover image|table of contents/i
      GENRE_STOP_WORDS = /CD-ROM|CD-ROMs|Compact discs|Computer network resources|Databases|Electronic book|Electronic books|Electronic government information|Electronic journal|Electronic journals|Electronic newspapers|Electronic reference sources|Electronic resource|Full text|Internet resource|Internet resources|Internet videos|Online databases|Online resources|Periodical|Periodicals|Sound recordings|Streaming audio|Streaming video|Video recording|Videorecording|Web site|Web sites|Périodiques|Congrès|Ressource Internet|Périodqiue électronique/i
      SEPARATOR = " — "

      def get_xml
        lambda do |rec, acc|
          acc << MARC::FastXMLWriter.encode(rec)
        end
      end

      def to_single_string
        Proc.new do |rec, acc|
          acc.replace [acc.join(" ")] # turn it into a single string
        end
      end

      def first_letters_only
        Proc.new do |rec, acc|
          # Just get the first letter to send to the translation map
          acc.map! { |x| x[0] }
        end
      end

      def creator_name_trim_punctuation(name)
        name.sub(/ *[,\/;:] *\Z/, "").sub(/( *[[:word:]]{3,})\. *\Z/, '\1').sub(/(?<=\))\./ , "")
      end

      def creator_role_trim_punctuation(role)
        role.sub(/ *[ ,.\/;:] *\Z/, "")
      end

      def extract_title_statement
        lambda do |rec, acc|
          titles = []
          slash = "/"

          Traject::MarcExtractor.cached("245abcfgknps", alternate_script: false).collect_matching_lines(rec) do |field, spec, extractor|
            title = extractor.collect_subfields(field, spec).first
            unless title.nil?
              rec.fields("245").each do |f|
                if field["h"].present? && field["c"].present?
                  title = title.gsub(" #{field['c']}", " #{slash} #{field['c']}")
                  title = title.gsub("/ /", "/")
                else
                  title
                end
              end
              title
            end
            titles << title
          end
          acc.replace(titles)
        end
      end

      def extract_creator
        lambda do |rec, acc|
          s_fields = Traject::MarcExtractor.cached("100abcqd:100ejlmnoprtu:110abdc:110elmnopt:111andcj:111elopt", alternate_script: false).collect_matching_lines(rec) do |field, spec, extractor|
            extractor.collect_subfields(field, spec).first
          end

          grouped_subfields = s_fields.each_slice(2).to_a
          grouped_subfields.each do |link|
            name = creator_name_trim_punctuation(link[0]) unless link[0].nil?
            role = creator_role_trim_punctuation(link[1]) unless link[1].nil?
            acc << [name, role].compact.join("|")
          end
          acc
        end
      end

      def extract_creator_vern
        lambda do |rec, acc|
          s_fields = Traject::MarcExtractor.cached("100abcqd:100ejlmnoprtu:110abdc:110elmnopt:111andcj:111elopt", alternate_script: :only).collect_matching_lines(rec) do |field, spec, extractor|
            extractor.collect_subfields(field, spec).first
          end

          grouped_subfields = s_fields.each_slice(2).to_a
          grouped_subfields.each do |link|
            name = creator_name_trim_punctuation(link[0]) unless link[0].nil?
            role = creator_role_trim_punctuation(link[1]) unless link[1].nil?
            acc << [name, role].compact.join("|")
          end
          acc
        end
      end

      def extract_contributor
        lambda do |rec, acc|
          s_fields = Traject::MarcExtractor.cached("700iabcqd:700ejlmnoprtu:710iabdc:710elmnopt:711iandcj:711elopt", alternate_script: false).collect_matching_lines(rec) do |field, spec, extractor|
            extractor.collect_subfields(field, spec).first
          end

          grouped_subfields = s_fields.each_slice(2).to_a
          grouped_subfields.each do |link|
            name = creator_name_trim_punctuation(link[0]) unless link[0].nil?
            role = creator_role_trim_punctuation(link[1]) unless link[1].nil?
            acc << [name, role].compact.join("|")
          end
          acc
        end
      end

      def extract_contributor_vern
        lambda do |rec, acc|
          s_fields = Traject::MarcExtractor.cached("700abcqd:700ejlmnoprtu:710abdc:710elmnopt:711andcj:711elopt", alternate_script: :only).collect_matching_lines(rec) do |field, spec, extractor|
            extractor.collect_subfields(field, spec).first
          end

          grouped_subfields = s_fields.each_slice(2).to_a
          grouped_subfields.each do |link|
            name = creator_name_trim_punctuation(link[0]) unless link[0].nil?
            role = creator_role_trim_punctuation(link[1]) unless link[1].nil?
            acc << [name, role].compact.join("|")
          end
          acc
        end
      end

      def extract_subject_display
        lambda do |rec, acc|
          subjects = []
          Traject::MarcExtractor.cached("600abcdefghklmnopqrstuvxyz:610abcdefghklmnoprstuvxyz:611acdefghjklnpqstuvxyz:630adefghklmnoprstvxyz:648axvyz:650abcdegvxyz:651aegvxyz:653a:654abcevyz:656akvxyz:657avxyz:690abcdegvxyz").collect_matching_lines(rec) do |field, spec, extractor|
            subject = extractor.collect_subfields(field, spec).first
            unless subject.nil?
              field.subfields.each do |s_field|
                subject = subject.gsub(" #{s_field.value}", "#{SEPARATOR}#{s_field.value}") if (s_field.code == "v" || s_field.code == "x" || s_field.code == "y" || s_field.code == "z")
              end
              subject = subject.split(SEPARATOR)
              subjects << subject.map { |s| Traject::Macros::Marc21.trim_punctuation(s) }.join(SEPARATOR)
            end
            subjects
          end
          acc.replace(subjects)
        end
      end

      def extract_genre_display
        lambda do |rec, acc|
          genres = []
          Traject::MarcExtractor.cached("655abcvxyz").collect_matching_lines(rec) do |field, spec, extractor|
            genre = extractor.collect_subfields(field, spec).first
            unless genre.nil?
              field.subfields.each do |s_field|
                genre = genre.gsub(" #{s_field.value}", "#{SEPARATOR}#{s_field.value}") if (s_field.code == "v" || s_field.code == "x" || s_field.code == "y" || s_field.code == "z")
              end
              genre = genre.split(SEPARATOR)
              genres << genre.map { |s| Traject::Macros::Marc21.trim_punctuation(s) }.join(SEPARATOR)
            end
            genres
          end
          acc.replace(genres)
        end
      end

      def extract_subject_topic_facet
        lambda do |rec, acc|
          subjects = []
          Traject::MarcExtractor.cached("600abcdq:610ab:611a:630a:653a:654ab:647acdg").collect_matching_lines(rec) do |field, spec, extractor|
            subject = extractor.collect_subfields(field, spec).fetch(0, "")
            subject = subject.split(SEPARATOR)
            subjects << subject.map { |s| Traject::Macros::Marc21.trim_punctuation(s) }
          end

          Traject::MarcExtractor.cached("650ax").collect_matching_lines(rec) do |field, spec, extractor|
            subject = extractor.collect_subfields(field, spec).first
            unless subject.nil?
              field.subfields.each do |s_field|
                if (s_field.code == "x")
                  subject = subject.gsub(" #{s_field.value}", "#{SEPARATOR}#{s_field.value}")
                end
              end
              subject = subject.split(SEPARATOR)
              subjects << subject.map { |s| Traject::Macros::Marc21.trim_punctuation(s) }.join(SEPARATOR)
            end
          end
          subjects = subjects.flatten
          acc.replace(subjects)
          acc.uniq!
        end
      end

      def extract_electronic_resource
        lambda do |rec, acc, context|
          rec.fields("PRT").each do |f|
            selected_subfields = {
              portfolio_id: f["a"],
              collection_id: f["i"],
              service_id: f["j"],
              title: f["c"],
              subtitle: f["g"],
              availability: f["9"] }
              .delete_if { |k, v| v.blank? }
              .to_json
            acc << selected_subfields
          end

          # Short circuit if PRT field present.
          if rec.fields("PRT").present?
            return acc
          end

          rec.fields("856").each do |f|
            if f.indicator2 != "2"
              label = url_label(f["z"], f["3"], f["y"])
              unless f["u"].nil?
                unless NOT_FULL_TEXT.match(label) || f["u"].include?(ARCHIVE_IT_LINKS)
                  acc << { title: label, url: f["u"] }.to_json
                end
              end
            end
          end
        end
      end

      def sort_electronic_resource!
        lambda do |rec, acc, context|
          begin
            acc.sort_by! { |r|
              subfields = JSON.parse(r)
              available = /Available from (\d{4})( until (\d{4}))?/.match(subfields["availability"])
              title = subfields["title"]
              subtitle = subfields["subtitle"]
              unless available
                available = []
              end
              [available[1] || "9999", available[3] || "9999", "#{title}", "#{subtitle}"]
            }.reverse!
          rescue
            logger.error("Failed `sort_electronic_resource!` on sorting #{rec}")
            acc
          end
        end
      end

      def url_label(z, n, y)
        label = [z, n].compact.join(" ")
        if label.empty?
          label = y || "Link to Resource"
        end
        label
      end

      def extract_url_more_links
        lambda { |rec, acc|
          rec.fields("856").each do |f|
            label = url_label(f["z"], f["3"], f["y"])
            unless f["u"].nil?
              if f.indicator2 == "2" || NOT_FULL_TEXT.match(label) || !rec.fields("PRT").empty? || f["u"].include?(ARCHIVE_IT_LINKS)
                unless f["u"].include?("http://library.temple.edu") && f["u"].include?("scrc")
                  acc << { title: label, url: f["u"] }.to_json
                end
              end
            end
          end
        }
      end

      def extract_url_finding_aid
        lambda { |rec, acc|
          rec.fields("856").each do |f|
            label = url_label(f["z"], f["3"], f["y"])
            if f.indicator1 == "4" && f.indicator2 == "2"
              unless f["u"].nil?
                if f["u"].include?("http://library.temple.edu") && f["u"].include?("scrc")
                  acc << { title: label, url: f["u"] }.to_json
                end
              end
            end
          end
        }
      end

      def extract_availability
        lambda { |rec, acc|
          unless rec.fields("PRT").empty?
            rec.fields("PRT").each do |field|
              acc << "Online" unless field["9"] == "Not Available"
            end
          end
          unless acc.include?("Online")
            rec.fields(["856"]).each do |field|
              z3 = [field["z"], field["3"]].join(" ")
              unless field["u"].nil?
                unless NOT_FULL_TEXT.match(z3) || rec.fields("856").empty? || field["u"].include?(ARCHIVE_IT_LINKS)
                  acc << "Online" if field.indicator1 == "4" && field.indicator2 != "2"
                end
              end
            end
          end

          unless rec.fields("HLD").empty?
            acc << "At the Library"
          end

          unless rec.fields("ADF").empty?
            acc << "At the Library"
          end

          order = []
          extract_purchase_order[rec, order]
          if order == [true]
            acc << "Request Rapid Access"
            acc << "Online"
          end

          acc.uniq!
        }
      end

      def extract_genre
        lambda do |rec, acc|
          MarcExtractor.cached("600v:610v:611v:630v:648v:650v:651v:655av:647v").collect_matching_lines(rec) do |field, spec, extractor|
            genre = extractor.collect_subfields(field, spec).first
            unless genre.nil?
              unless GENRE_STOP_WORDS.match(genre.force_encoding(Encoding::UTF_8).unicode_normalize)
                acc << genre.gsub(/[^[:alnum:])]*$/, "")
              end
            end
            acc.uniq!
          end
        end
      end

      def normalize_lc_alpha
        Proc.new do |rec, acc|
          alpha_pat = /\A([A-Z]{1,3})\d.*\Z/
          acc.map! do |x|
            (m = alpha_pat.match(x)) ? m[1] : nil
          end
          acc.compact! # eliminate nils
        end
      end

      def normalize_format
        Proc.new do |rec, acc|
          acc.delete("Print")
          acc.delete("Online")
          # replace Archival with Archival Material
          acc.map! { |x| x == "Archival" ? "Archival Material" : x }.flatten!
          # replace Conference with Conference Proceedings
          acc.map! { |x| x == "Conference" ? "Conference Proceedings" : x }.flatten!
        end
      end

      def normalize_isbn
        Proc.new do |rec, acc|
          orig = acc.dup
          acc.map! { |x| StdNum::ISBN.allNormalizedValues(x) }
          acc << orig
          acc.flatten!
          acc.uniq!
        end
      end

      def normalize_issn
        Proc.new do |rec, acc|
          orig = acc.dup
          acc.map! { |x| StdNum::ISSN.normalize(x) }
          acc << orig
          acc.flatten!
          acc.uniq!
        end
      end

      def normalize_lccn
        Proc.new do |rec, acc|
          orig = acc.dup
          acc.map! { |x| StdNum::LCCN.normalize(x) }
          acc << orig
          acc.flatten!
          acc.uniq!
        end
      end

      def truncate(max = 300)
        Proc.new do |rec, acc|
          acc.map! { |s| s.length > max ? s[0...max] + " ..." : s unless s.nil? }
        end
      end

      # Just like marc_languages except it makes a special case for "041a" spec.
      def extract_lang(spec = "008[35-37]:041a:041d")
        translation_map = Traject::TranslationMap.new("marc_languages")

        extractor = MarcExtractor.new(spec, separator: nil)
        spec_041a = Traject::MarcExtractor::Spec.new(tag: "041", subfields: ["a"])

        lambda do |record, accumulator|
          codes = extractor.collect_matching_lines(record) do |field, spec, extractor|
            if extractor.control_field?(field)
              (spec.bytes ? field.value.byteslice(spec.bytes) : field.value)
            else
              extractor.collect_subfields(field, spec).collect do |value|
                # sometimes multiple language codes are jammed together in one subfield, and
                # we need to separate ourselves. sigh.
                if spec == spec_041a
                  value = value[0..2]
                end

                unless value.length == 3
                  # split into an array of 3-length substrs; JRuby has problems with regexes
                  # across threads, which is why we don't use String#scan here.
                  value = value.chars.each_slice(3).map(&:join)
                end
                value
              end.flatten
            end
          end
          codes = codes.uniq

          translation_map.translate_array!(codes)

          accumulator.concat codes
        end
      end

      def extract_library
        lambda do |rec, acc|
          rec.fields(["HLD"]).each do |field|
            if field["b"] != "RES_SHARE"
              acc << Traject::TranslationMap.new("libraries_map")[field["b"]]
            end
          end
        end
      end

      def extract_library_shelf_call_number
        lambda do |rec, acc|
          rec.fields(["HLD"]).each do |field|
            if field["b"] != "RES_SHARE"
              location = Traject::TranslationMap.new("libraries_map")[field["b"]]
              shelf = Traject::TranslationMap.new("shelf_map")[field["c"]]
              call_number = field["h"]
              acc << "#{location} (#{shelf})\n(#{call_number})"
            end
          end
        end
      end

      def extract_pub_date
        lambda do |rec, acc|
          rec.fields(["008"]).each do |field|
            # [TODO] date_pub_status for future use. How should we display date data depending on value of date_pub_status?
            date_pub_status = Traject::TranslationMap.new("marc_date_type_pub_status")[field.value[6]]
            date1 = field.value[7..10]
            # [TODO] date2 for future use. How should we display dates if there are a date1 and date2?
            date2 = field.value[11..14]
            acc << date1 unless date1.nil?
          end
        end
      end

      def extract_pub_datetime
        lambda do |rec, acc|
          rec.fields(["260"]).each do |field|
            acc << four_digit_year(field["c"]) unless field["c"].nil?
          end

          rec.fields(["264"]).each do |field|
            acc << four_digit_year(field["c"]) unless field["c"].nil? || field.indicator2 == "4"
          end
          if !acc.empty?
            acc.replace [Date.ordinal(acc.first.to_i, 1).strftime("%FT%TZ")]
          end
        end
      end

      def extract_copyright
        lambda do |rec, acc|
          rec.fields(["264"]).each do |field|
            acc << four_digit_year(field["c"]) if field.indicator2 == "4"
          end
        end
      end

      def extract_marc_with_flank(*args)
        marc_proc = extract_marc(*args)

        lambda do |record, accumulator, context|
          accumulator << marc_proc.call(record, accumulator, context)
          accumulator.map! { |v| flank v }
        end
      end

      def flank(string = "", starts = nil, ends = nil)
        starts ||= "matchbeginswith"
        ends ||= "matchendswith"
        if !string.to_s.empty? && !string.match(/^#{starts}/)
          "#{starts} #{string} #{ends}"
        else
          string
        end
      end

      def suppress_items
        lambda do |rec, acc, context|
          asrs = rec.fields("ITM").select { |field| field["f"] == "ASRS" && field["g"] == "ASRS_TEST" }
          unassigned = rec.fields("ITM").select { |field| field["g"] == "UNASSIGNED" }
          lost = rec.fields("ITM").select { |field| field["u"] == "LOST_LOAN" }
          missing = rec.fields("ITM").select { |field| field["u"] == "MISSING" }
          technical = rec.fields("ITM").select { |field| field["u"] == "TECHNICAL" }
          unwanted_library = rec.fields("HLD").select { |field| field["b"] == "EMPTY" || field["c"] == "UNASSIGNED" }

          if rec.fields("ITM").length == 1 && (!lost.empty? || !missing.empty? || !technical.empty? || !asrs.empty? || !unassigned.empty?)
            acc.replace([true])
          elsif rec.fields("HLD").length == 1 && !unwanted_library.empty?
            acc.replace([true])
          end

          if acc == [true] && ENV["TRAJECT_FULL_REINDEX"] == "yes"
            context.skip!
          end

        end
      end

      def extract_oclc_number
        lambda do |rec, acc|
          rec.fields(["035", "979"]).each do |field|
            unless field.nil?
              unless field["a"].nil? || field["9"]&.include?("ExL")
                if field["a"].include?("OCoLC") || field["a"].include?("ocn") || field["a"].include?("ocm") || field["a"].match(/\bon[0-9]/) || field["a"].include?("OCLC")
                  subfield = field["a"].split(//).map { |x| x[/\d+/] }.compact.join("")
                end
                acc << subfield
              end
            end
            acc.uniq!
          end
        end
      end

      def extract_item_info
        lambda do |rec, acc, context|
          holding_ids = rec.fields("HLD").map  { |field| field["8"] }.compact.uniq
          item_holding_ids = rec.fields("ITM").map { |field| field["r"] }.compact.uniq
          holding_ids_with_no_items = holding_ids - item_holding_ids

          holding_ids_with_no_items.each  do |holding_id|
            rec.fields("HLD").select { |field| field["8"] == holding_id }.each do |field|
              summary = rec.fields(["HLD866"]).select { |h| h["8"] == field["8"] }
                .map { |h| h["a"] }
                .first

              selected_subfields = {
                  holding_id: field["8"],
                  current_library: field["b"],
                  current_location: field["c"],
                  call_number: field["h"].to_s + field["i"].to_s,
                  summary: summary }
                .delete_if { |k, v| v.blank? }
                .to_json


              acc << selected_subfields
            end
          end

          rec.fields("ITM").each do |f|
            summary = rec.fields(["HLD866"]).select { |h| h["8"] == f["r"] }
              .map { |h| h["a"] }
              .first

            selected_subfields = {
              item_pid: f["8"],
              item_policy: f["a"],
              description: f["c"],
              permanent_library: f["d"],
              permanent_location: f["e"],
              current_library: f["f"],
              current_location: f["g"],
              call_number_type: f["h"],
              call_number: f["i"],
              alt_call_number_type: f["j"],
              alt_call_number: f["k"],
              temp_call_number_type: f["l"],
              temp_call_number: f["m"],
              public_note: f["o"],
              due_back_date: f["p"],
              holding_id: f["r"],
              material_type: f["t"],
              summary: summary,
              process_type: f["u"] }
              .delete_if { |k, v| v.blank? }
              .to_json

            acc << selected_subfields
          end
        end
      end

      # In order to reduce the relevance of certain libraries, we need to boost every other library
      # Make sure we still boost records what have holdings in less relevant libraries and also in another library
      LIBRARIES_TO_NOT_BOOST = [ "PRESSER", "CLAEDTECH" ]
      def library_based_boost
        lambda do |rec, acc|
          rec.fields(["HLD"]).each do |field|
            if  !LIBRARIES_TO_NOT_BOOST.include?(field["b"])
              return acc.replace(["boost"])
            else
              acc << "no_boost"
            end
          end
        end
      end

      def extract_work_access_point
        lambda do |rec, acc|
          if rec["130"].present?
            spec = "130adfklmnoprs"
          elsif rec["240"].present? && rec["100"].present?
            spec = "100abdcdq:240adfklmnoprs"
          elsif rec["240"].present? && rec["110"].present?
            spec = "110abcd:240adfklmnoprs"
          elsif rec["100"]
            spec = "100abcdq:245aknp"
          elsif rec["110"]
            spec = "110abcd:245aknp"
          else
            # Skip because alternative is just the regular title.
            return acc
          end

          acc << Traject::MarcExtractor.cached(spec).extract(rec).join(" . ")
        end
      end

      def extract_purchase_order
        lambda do |rec, acc|
          acc << Traject::MarcExtractor.cached("902a").extract(rec).any? { |s| s.match?(/EBC-POD/) } || false
        end
      end

      def extract_update_date
        lambda do |rec, acc|
          latest_date = [
            rec.fields("ADM").map { |f| [ f["a"], f["b"] ] },
            rec.fields("PRT").map { |f| [ f["created"], f["updated"] ] },
            rec.fields("HLD").map { |f| [ f["created"], f["updated"] ] },
            rec.fields("ITM").map { |f| f["q"] } ]
            .flatten.compact.uniq.map { |t| Time.parse(t) }
            .sort.last.to_s

          if ENV["SOLR_DISABLE_UPDATE_DATE_CHECK"] == "yes"
            latest_date = Time.now.to_s
          end

          acc << latest_date unless latest_date.empty?
        end
      end
    end
  end
end
