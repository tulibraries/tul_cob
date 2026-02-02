# frozen_string_literal: true

require "csv"

module CsvExportable
  HEADERS = [
    "Title",
    "Imprint",
    "Author",
    "Contributor",
    "ISBN",
    "Located At",
    "Library Search URL"
  ].freeze

  def self.extended(document)
    document.will_export_as(:csv, "text/csv")
  end

  def export_as_csv
    CSV.generate_line(csv_fields, row_sep: "")
  end

  def csv_fields
    [
      csv_title_value,
      csv_imprint_value,
      csv_value("creator_display"),
      csv_contributor_value,
      csv_value("isbn_display"),
      csv_located_at_value
    ]
  end

  private

    def csv_title_value
      title_value = csv_value("title_with_subtitle_display")
      return title_value if title_value.present?

      title_value = csv_value("title_with_subtitle_truncated_display")
      return title_value if title_value.present?

      csv_value("title_statement_display")
    end

    def csv_value(field)
      Array(fetch(field, nil)).compact.join("; ")
    end

    def csv_imprint_value
      value = csv_value("imprint_display")
      return value if value.present?

      value = csv_value("imprint_prod_display")
      return value if value.present?

      value = csv_value("imprint_dist_display")
      return value if value.present?

      csv_value("imprint_man_display")
    end

    def csv_contributor_value
      contributors = Array(fetch("contributor_display", nil)).filter_map do |value|
        extract_contributor_name(value)
      end

      contributors.join("; ")
    end

    def extract_contributor_name(value)
      return "" if value.blank?
      return value["name"].to_s.strip if value.is_a?(Hash)

      text = value.to_s.strip
      return "" if text.blank?
      return text unless text.start_with?("{") && text.end_with?("}")

      parsed = JSON.parse(text)
      parsed.is_a?(Hash) ? parsed["name"].to_s.strip : text
    rescue JSON::ParserError
      text
    end

    def csv_located_at_value
      return "" unless respond_to?(:document_items_grouped)

      holdings = document_items_grouped.flat_map do |library, locations|
        locations.flat_map do |location, items|
          items.map do |item|
            parts = [library, location, item["call_number_display"]].compact
            parts.reject(&:blank?).join(" - ")
          end
        end
      end

      holdings.uniq.join("; ")
    end
end
