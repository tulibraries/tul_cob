# frozen_string_literal: false

require "library_stdnums"

# A set of custom traject macros (extractors and normalizers) used by the
module Traject
  module Macros
    module Custom
      NOT_FULL_TEXT = /book review|publisher description|sample text|table of contents/i
      GENRE_STOP_WORDS = /CD-ROM|CD-ROMs|Compact discs|Computer network resources|Databases|Electronic book|Electronic books|Electronic government information|Electronic journal|Electronic journals|Electronic newspapers|Electronic reference sources|Electronic resource|Full text|Internet resource|Internet resources|Internet videos|Online databases|Online resources|Periodical|Periodicals|Sound recordings|Streaming audio|Streaming video|Video recording|Videorecording|Web site|Web sites|Périodiques|Congrès|Ressource Internet|Périodqiue électronique/i
      SEPARATOR = '—'

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
        name.sub(/ *[ ,\/;:] *\Z/, "").sub(/( *[[:word:]]{3,})\. *\Z/, '\1').sub(/(?<=\))\./ , "")
      end

      def creator_role_trim_punctuation(role)
        role.sub(/ *[ ,.\/;:] *\Z/, "")
      end

      def extract_creator
        lambda do |rec, acc|
          rec.fields("100").each do |f|
            linked_subfields = [f["a"], f["b"], f["c"], f["q"], f["d"]].compact.join(" ")
            plain_text_subfields = [f["e"], f["j"], f["l"], f["m"], f["n"], f["o"], f["p"], f["r"], f["t"], f["u"]].compact.join(" ")
            acc << creator_name_trim_punctuation(linked_subfields) + "|" + creator_role_trim_punctuation(plain_text_subfields)
          end
          rec.fields("110").each do |f|
            linked_subfields = [f["a"], f["b"], f["d"], f["c"]].compact.join(" ")
            plain_text_subfields = [f["e"], f["l"], f["m"], f["n"], f["o"], f["p"], f["t"]].compact.join(" ")
            acc << creator_name_trim_punctuation(linked_subfields) + "|" + creator_role_trim_punctuation(plain_text_subfields)
          end
          rec.fields("111").each do |f|
            linked_subfields = [f["a"], f["n"], f["d"], f["c"], f["j"]].compact.join(" ")
            plain_text_subfields = [f["e"], f["l"], f["o"], f["p"], f["t"]].compact.join(" ")
            acc << creator_name_trim_punctuation(linked_subfields) + "|" + creator_role_trim_punctuation(plain_text_subfields)
          end
        end
      end

      def extract_creator_vern
        lambda do |rec, acc|
          MarcExtractor.cached("100abcdejlmnopqrtu", alternate_script: :only).collect_matching_lines(rec) do |f|
            linked_subfields = [f["a"], f["b"], f["c"], f["q"], f["d"]].compact.join(" ")
            plain_text_subfields = [f["e"], f["j"], f["l"], f["m"], f["n"], f["o"], f["p"], f["r"], f["t"], f["u"]].compact.join(" ")
            acc << creator_name_trim_punctuation(linked_subfields) + "|" + creator_role_trim_punctuation(plain_text_subfields)
          end
          MarcExtractor.cached("110abcdelmnopt", alternate_script: :only).collect_matching_lines(rec) do |f|
            linked_subfields = [f["a"], f["b"], f["d"], f["c"]].compact.join(" ")
            plain_text_subfields = [f["e"], f["l"], f["m"], f["n"], f["o"], f["p"], f["t"]].compact.join(" ")
            acc << creator_name_trim_punctuation(linked_subfields) + "|" + creator_role_trim_punctuation(plain_text_subfields)
          end
          MarcExtractor.cached("111acdejlnopt", alternate_script: :only).collect_matching_lines(rec) do |f|
            linked_subfields = [f["a"], f["n"], f["d"], f["c"], f["j"]].compact.join(" ")
            plain_text_subfields = [f["e"], f["l"], f["o"], f["p"], f["t"]].compact.join(" ")
            acc << creator_name_trim_punctuation(linked_subfields) + "|" + creator_role_trim_punctuation(plain_text_subfields)
          end
        end
      end

      def extract_contributor
        lambda do |rec, acc|
          rec.fields("700").each do |f|
            linked_subfields = [f["a"], f["b"], f["c"], f["q"], f["d"]].compact.join(" ")
            plain_text_subfields = [f["e"], f["j"], f["l"], f["m"], f["n"], f["o"], f["p"], f["r"], f["t"], f["u"]].compact.join(" ")
            acc << creator_name_trim_punctuation(linked_subfields) + "|" + creator_role_trim_punctuation(plain_text_subfields)
          end
          rec.fields("710").each do |f|
            linked_subfields = [f["a"], f["b"], f["d"], f["c"]].compact.join(" ")
            plain_text_subfields = [f["e"], f["l"], f["m"], f["n"], f["o"], f["p"], f["t"]].compact.join(" ")
            acc << creator_name_trim_punctuation(linked_subfields) + "|" + creator_role_trim_punctuation(plain_text_subfields)
          end
          rec.fields("711").each do |f|
            linked_subfields = [f["a"], f["n"], f["d"], f["c"], f["j"]].compact.join(" ")
            plain_text_subfields = [f["e"], f["l"], f["o"], f["p"], f["t"]].compact.join(" ")
            acc << creator_name_trim_punctuation(linked_subfields) + "|" + creator_role_trim_punctuation(plain_text_subfields)
          end
        end
      end

      def extract_contributor_vern
        lambda do |rec, acc|
          MarcExtractor.cached("700abcdejlmnopqrtu", alternate_script: :only).collect_matching_lines(rec) do |f|
            linked_subfields = [f["a"], f["b"], f["c"], f["q"], f["d"]].compact.join(" ")
            plain_text_subfields = [f["e"], f["j"], f["l"], f["m"], f["n"], f["o"], f["p"], f["r"], f["t"], f["u"]].compact.join(" ")
            acc << creator_name_trim_punctuation(linked_subfields) + "|" + creator_role_trim_punctuation(plain_text_subfields)
          end
          MarcExtractor.cached("710abcdelmnopt", alternate_script: :only).collect_matching_lines(rec) do |f|
            linked_subfields = [f["a"], f["b"], f["d"], f["c"]].compact.join(" ")
            plain_text_subfields = [f["e"], f["l"], f["m"], f["n"], f["o"], f["p"], f["t"]].compact.join(" ")
            acc << creator_name_trim_punctuation(linked_subfields) + "|" + creator_role_trim_punctuation(plain_text_subfields)
          end
          MarcExtractor.cached("711acdejlnopt", alternate_script: :only).collect_matching_lines(rec) do |f|
            linked_subfields = [f["a"], f["n"], f["d"], f["c"], f["j"]].compact.join(" ")
            plain_text_subfields = [f["e"], f["l"], f["o"], f["p"], f["t"]].compact.join(" ")
            acc << creator_name_trim_punctuation(linked_subfields) + "|" + creator_role_trim_punctuation(plain_text_subfields)
          end
        end
      end

      def process_subject_topic_facet rec
          subjects = []
          Traject::MarcExtractor.cached("600abcdq:610ab:611a:630a:650ax:653a:654ab:647acdg").collect_matching_lines(rec) do |field, spec, extractor|
            subject = extractor.collect_subfields(field, spec).first
            unless subject.nil?
              field.subfields.each do |s_field|
                if (s_field.code == 'x')
                  subject = subject.gsub(" #{s_field.value}", "#{SEPARATOR}#{s_field.value}")
                end
              end
              subject = subject.split(SEPARATOR)
              subjects << subject.map { |s| Traject::Macros::Marc21.trim_punctuation(s) }
            end
          end
          subjects.flatten
      end

      def extract_electronic_resource
        lambda do |rec, acc, context|
          rec.fields("PRT").each do |f|
            selected_subfields = [f["a"], f["c"], f["g"]].compact.join("|")
            acc << selected_subfields
          end
          # Short circuit if PRT field present.
          if !rec.fields("PRT").empty?
            return acc
          end

          rec.fields("856").each do |f|
            if f.indicator2 != "2"
              label = url_label(f["z"], f["3"], f["y"])
              unless NOT_FULL_TEXT.match(label)
                acc << [label, f["u"]].compact.join("|")
              end
            end
          end
        end
      end

      def sort_electronic_resource!
        lambda do |rec, acc, context|
          begin
            acc.sort_by! { |r|
              subfields = r.split("|")
              available = /Available from (\d{4})( until (\d{4}))?/.match(r)
              title = subfields[1]
              subtitle = subfields[2]
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
            if f.indicator2 == "2" || NOT_FULL_TEXT.match(label) || !rec.fields("PRT").empty?
              acc << [label, f["u"]].compact.join("|")
            end
          end
        }
      end

      def extract_availability
        lambda { |rec, acc|
          unless rec.fields("PRT").empty?
            acc << "Online"
          end
          unless acc.include?("Online")
            rec.fields(["856"]).each do |field|
              z3 = [field["z"], field["3"]].join(" ")
              unless NOT_FULL_TEXT.match(z3) || rec.fields("856").empty?
                acc << "Online" if field.indicator1 == "4" && field.indicator2 != "2"
              end
            end
          end
          unless rec.fields("HLD").empty?
            acc << "At the Library"
          end
          acc.uniq!
        }
      end

      def extract_genre
        lambda do |rec, acc|
          MarcExtractor.cached("600v:610v:611v:630v:648v:650v:651v:655av:647v").collect_matching_lines(rec) do |field, spec, extractor|
            genre = extractor.collect_subfields(field, spec).first
            unless GENRE_STOP_WORDS.match(genre)
              acc << genre.gsub(/[^[:alnum:])]*$/, "") unless genre.nil?
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

      def extract_library
        lambda do |rec, acc|
          rec.fields(["HLD"]).each do |field|
            if field["b"] != "RES_SHARE"
              acc << Traject::TranslationMap.new("locations_map")[field["b"]]
            end
          end
        end
      end

      def extract_library_shelf_call_number
        lambda do |rec, acc|
          rec.fields(["HLD"]).each do |field|
            if field["b"] != "RES_SHARE"
              location = Traject::TranslationMap.new("locations_map")[field["b"]]
              shelf = Traject::TranslationMap.new("shelf_map")[field["c"]]
              call_number = field["h"]
              acc << "#{location} (#{shelf})\n(#{call_number})"
            end
          end
        end
      end

      def extract_pub_date
        lambda do |rec, acc|
          rec.fields(["260"]).each do |field|
            acc << four_digit_year(field["c"]) unless field["c"].nil?
          end

          rec.fields(["264"]).each do |field|
            acc << four_digit_year(field["c"]) unless field["c"].nil? || field.indicator2 == "4"
          end
        end
      end

      def extract_copyright
        lambda do |rec, acc|
          rec.fields(["260"]).each do |field|
            unless field["c"].nil?
              acc << four_digit_year(field["c"]) if field["c"].include?("c") || field["c"].include?("p") || field["c"].include?("\u00A9")
            end
          end
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
    end
  end
end
