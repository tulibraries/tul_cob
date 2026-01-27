# frozen_string_literal: true

require "csv"

module CsvExportable
  HEADERS = [
    "Title",
    "Author",
    "Call Number",
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
      csv_value("title_statement_display"),
      csv_value("creator_display"),
      csv_value("call_number_display")
    ]
  end

  private

  def csv_value(field)
    Array(fetch(field, nil)).compact.join("; ")
  end
end
