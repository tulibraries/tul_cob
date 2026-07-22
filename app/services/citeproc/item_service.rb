# frozen_string_literal: true

module Citeproc
  class ItemService
    ROLE_MAPPINGS = {
      "author" => "author",
      "aut" => "author",
      "editor" => "editor",
      "edt" => "editor",
      "translator" => "translator",
      "trl" => "translator",
      "illustrator" => "illustrator",
      "ill" => "illustrator"
    }.freeze

    def self.build(document)
      new(document).item
    end

    def initialize(document)
      @document = document
    end

    attr_reader :document

    def item
      return if normalized_title.blank?

      ::CiteProc::Item.new(item_attributes.compact_blank)
    end

    private

      def item_attributes
        {
          id: document.id.to_s,
          type: csl_type,
          title: normalized_title,
          author: extract_names("author"),
          editor: extract_names("editor"),
          translator: extract_names("translator"),
          illustrator: extract_names("illustrator"),
          issued: issued_date,
          publisher: publisher,
          publisher_place: publisher_place,
          ISBN: isbn,
          ISSN: issn
        }
      end

      def normalized_title
        return @normalized_title if defined?(@normalized_title)

        title = Array(document["title_with_subtitle_display"]).first ||
          Array(document["title_with_subtitle_truncated_display"]).first ||
          Array(document["title_statement_display"]).first

        @normalized_title = normalize_title(title)
      end

      def normalize_title(value)
        title = value.to_s.split(%r{\s+/\s+}, 2).first.to_s
        title = title.gsub(/\s+/, " ").strip
        title.presence
      end

      def issued_date
        year = publication_year
        return if year.blank?

        { "date-parts" => [[year.to_i]] }
      end

      def publication_year
        candidates = [
          Array(document["pub_date_display"]).first,
          Array(document["pub_date"]).first,
          document["date_copyright_display"]
        ].compact.map(&:to_s)

        candidates.join(" ")[/\b\d{4}\b/]
      end

      def csl_type
        formats = Array(document["format"])
        return "book" if formats.include?("Book")
        return "article-journal" if formats.include?("Journal/Periodical") || formats.include?("Article")
        return "thesis" if formats.include?("Dissertation/Thesis")

        "document"
      end

      def imprint
        Array(document["imprint_display"]).first ||
          Array(document["imprint_prod_display"]).first ||
          Array(document["imprint_dist_display"]).first ||
          Array(document["imprint_man_display"]).first
      end

      def publisher_place
        return if imprint.blank?

        imprint.to_s.split(":").first.to_s.strip.presence
      end

      def publisher
        return if imprint.blank?

        parts = imprint.to_s.split(":")
        publisher_section = parts.length > 1 ? parts.last : parts.first
        publisher_section.to_s.split(",").first.to_s.strip.presence
      end

      def isbn
        Array(document["isbn_display"]).first
      end

      def issn
        Array(document["issn_display"]).first
      end

      def extract_names(target_role)
        extract_main_entry_names(target_role) + extract_contributor_names(target_role)
      end

      def extract_main_entry_names(target_role)
        Array(document["creator_display"]).filter_map do |value|
          role = extract_role(value, default_role: "author")
          extract_name(value) if role == target_role
        end.uniq
      end

      def extract_contributor_names(target_role)
        Array(document["contributor_display"]).filter_map do |value|
          role = extract_role(value, default_role: default_role_for_contributor_entries)
          extract_name(value) if role == target_role
        end.uniq
      end

      def default_role_for_contributor_entries
        return unless Array(document["creator_display"]).blank?

        "author"
      end

      def extract_name(value)
        name = parsed_indexed_value(value)[:name]
        build_name(name)
      end

      def build_name(value)
        return if value.blank?

        normalized_value = strip_trailing_meeting_metadata(strip_trailing_name_dates(value))

        if personal_name?(normalized_value)
          family, given = normalized_value.split(",", 2).map(&:strip)
          { family: strip_trailing_name_dates(family), given: strip_trailing_name_dates(given).presence }
        else
          { literal: normalized_value }
        end
      end

      def personal_name?(value)
        value.count(",") == 1
      end

      def extract_role(value, default_role: nil)
        relator_segments(value).each do |segment|
          role = ROLE_MAPPINGS[normalize_relator(segment)]
          return role if role.present?
        end

        default_role
      end

      def relator_segments(value)
        parsed = parsed_indexed_value(value)
        Array(parsed[:relators])
      end

      def normalize_relator(value)
        normalized = strip_trailing_punct(value).downcase
        normalized.include?("relators/") ? normalized.split("/").last : normalized
      end

      def parsed_indexed_value(value)
        return parse_json_indexed_value(value) if json_indexed_value?(value)

        parse_pipe_indexed_value(value)
      end

      def json_indexed_value?(value)
        string = value.to_s.strip
        string.start_with?("{") && string.end_with?("}")
      end

      def parse_json_indexed_value(value)
        parsed = JSON.parse(value.to_s)
        {
          name: parsed["name"].to_s.strip,
          relators: [parsed["role"], parsed["relation"]].compact_blank
        }
      rescue JSON::ParserError
        parse_pipe_indexed_value(value)
      end

      def parse_pipe_indexed_value(value)
        segments = value.to_s.split("|").map(&:strip)
        {
          name: segments.first.to_s,
          relators: segments.drop(1)
        }
      end

      def strip_trailing_punct(value)
        value.to_s.strip.gsub(/[.,:;\/]+\z/, "")
      end

      def strip_trailing_name_dates(value)
        normalized = strip_trailing_punct(value)
          .sub(/\s*\((?:ca\.?\s*)?\d{3,4}(?:\s*-\s*\d{0,4}\??)?\)\z/i, "")
          .sub(/,\s*b\.\s*\d{3,4}\z/i, "")
          .sub(/,\s*d\.\s*\d{3,4}\z/i, "")
          .sub(/,\s+(?:ca\.?|approximately)?\s*\d{3,4}\s*-\s*(?:ca\.?|approximately)?\s*\d{0,4}\??\z/i, "")
          .sub(/,\s+(?:ca\.?|approximately)?\s*\d{3,4}\??\z/i, "")

        strip_trailing_punct(normalized)
          .strip
      end

      def strip_trailing_meeting_metadata(value)
        normalized = value.to_s.gsub(/\s+/, " ").strip
        normalized = normalized
          .sub(/\s*\((?=[^)]*\d{4})(?=[^)]*:)[^)]*\)\z/, "")
          .sub(/\s+\(?\d+(?:st|nd|rd|th)?\s*:\s*\d{4}\s*:\s*[^)]*\)?\z/i, "")
          .sub(/\s+\(?\d{4}\s*:\s*[^)]*\)?\z/i, "")
          .strip

        strip_trailing_punct(normalized)
      end
  end
end
