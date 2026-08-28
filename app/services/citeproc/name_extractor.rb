# frozen_string_literal: true

module Citeproc
  class NameExtractor
    Entry = Struct.new(:name, :relators, keyword_init: true)

    def initialize(document)
      @document = document
    end

    attr_reader :document

    def creator_entries
      @creator_entries ||= entries_for("creator_display", "creator")
    end

    def contributor_entries
      @contributor_entries ||= entries_for("contributor_display", "contributor")
    end

    def fallback_contributor_entries
      entries = contributor_entries
      return entries if entries.present?

      marc_contributor_entries
    end

    private

      def entries_for(*fields)
        values_for(*fields).filter_map do |value|
          build_entry(value)
        end
      end

      def values_for(*fields)
        fields.each do |field|
          values = Array(document[field]).compact_blank
          return values if values.present?
        end

        []
      end

      def build_entry(value)
        parsed = parse_value(value)
        return if parsed[:name].blank?

        Entry.new(name: parsed[:name], relators: Array(parsed[:relators]).compact_blank)
      end

      def parse_value(value)
        return parse_html_value(value) if html_value?(value)
        return parse_json_value(value) if json_value?(value)

        parse_pipe_value(value)
      end

      def html_value?(value)
        value.to_s.include?("<")
      end

      def json_value?(value)
        string = value.to_s.strip
        string.start_with?("{") && string.end_with?("}")
      end

      def parse_html_value(value)
        string = value.to_s
        anchor_text = string[/>([^<]+)<\/a>/i, 1].to_s
        trailing_text = string.split(%r{</a>}i, 2).last.to_s

        {
          name: sanitize_text(anchor_text),
          relators: [sanitize_text(trailing_text)]
        }
      end

      def parse_json_value(value)
        parsed = JSON.parse(value.to_s)
        {
          name: parsed["name"].to_s.strip,
          relators: [parsed["role"], parsed["relation"]]
        }
      rescue JSON::ParserError
        parse_pipe_value(value)
      end

      def parse_pipe_value(value)
        segments = value.to_s.split("|").map(&:strip)
        {
          name: segments.first.to_s,
          relators: segments.drop(1)
        }
      end

      def sanitize_text(value)
        CGI.unescapeHTML(value.to_s.gsub(/<[^>]+>/, " ")).squish
      end

      def marc_contributor_entries
        return [] unless document.respond_to?(:to_marc)

        Array(document.to_marc&.fields).select do |field|
          %w[700 710 711].include?(field.tag)
        end.filter_map do |field|
          build_entry(marc_name_value(field))
        end
      rescue StandardError
        []
      end

      def marc_name_value(field)
        return if field.blank?

        subfields = field.subfields.select do |subfield|
          %w[a b c d q].include?(subfield.code)
        end
        return if subfields.blank?

        subfields.map(&:value).join(" ").squish
      end
  end
end
