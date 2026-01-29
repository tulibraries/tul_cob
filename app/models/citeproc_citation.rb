# frozen_string_literal: true

require "citeproc"
require "csl"
require "csl/styles"

class CiteprocCitation
  STYLE_MAP = {
    "APA" => "apa",
    "CHICAGO-AUTHOR-DATE" => "chicago-author-date",
    "CHICAGO-NOTES-BIBLIOGRAPHY" => "chicago-notes-bibliography",
    "MLA" => "modern-language-association"
  }.freeze

  def initialize(document, formats = [])
    @document = document
    @formats = formats
  end

  def citable?
    title.present?
  end

  def citations
    return null_citation if return_null_citation?

    styles = all_formats_requested? ? STYLE_MAP : STYLE_MAP.slice(*desired_formats)
    styles.each_with_object({}) do |(label, style_id), hash|
      citation = render_style(style_id, label)
      hash[label] = citation if citation.present?
    end
  end

  private

    attr_reader :document, :formats

    def return_null_citation?
      title.blank?
    end

    def all_formats_requested?
      desired_formats == ["ALL"]
    end

    def desired_formats
      return STYLE_MAP.keys if formats.blank?
      formats.map(&:upcase)
    end

    def render_style(style_id, label)
      processor = CiteProc::Processor.new(style: load_style(style_id), format: "html")
      processor.import([csl_item])
      result = Array(processor.render(:bibliography)).first.to_s
      return "" if result.blank?

      %(<p class="citation_style_#{label}">#{result}</p>).html_safe
    rescue StandardError => e
      Rails.logger.warn("Citeproc failed for #{style_id}: #{e}")
      ""
    end

    def load_style(style_id)
      CSL::Style.load(style_id)
    end

    def csl_item
      @csl_item ||= begin
        attributes = {
          id: document.id.to_s,
          type: csl_type,
          title: title,
          author: csl_names(author_names),
          editor: csl_names(editor_names),
          issued: issued_date,
          publisher: publisher,
          publisher_place: publisher_place,
          ISBN: isbn,
          ISSN: issn
        }.compact
        CSL::Item.new(attributes)
      end
    end

    def title
      Array(document["title_statement_display"]).first.to_s.presence
    end

    def author_names
      Array(document["creator_display"]).presence ||
        Array(document["contributor_display"]).presence ||
        []
    end

    def editor_names
      return [] if Array(document["creator_display"]).present?
      Array(document["contributor_display"])
    end

    def csl_names(names)
      Array(names).map do |name|
        CSL::Name.parse(name.to_s)
      rescue StandardError
        CSL::Name.new(literal: name.to_s)
      end
    end

    def issued_date
      year = publication_year
      return nil if year.blank?

      { "date-parts" => [[year.to_i]] }
    end

    def publication_year
      candidates = [
        Array(document["pub_date_display"]).first,
        Array(document["pub_date"]).first,
        document["date_copyright_display"]
      ].compact.map(&:to_s)

      match = candidates.join(" ").match(/\b\d{4}\b/)
      match&.to_s
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
      return nil if imprint.blank?
      imprint.to_s.split(":").first.to_s.strip.presence
    end

    def publisher
      return nil if imprint.blank?
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

    def null_citation
      { "NULL" => "<p>No citation available for this record</p>".html_safe }
    end
end
