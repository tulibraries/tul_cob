# frozen_string_literal: true

require "citeproc"
require "citeproc/ruby"
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
    csl_item.present?
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
      csl_item.blank?
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
      bibliography = processor.bibliography
      result = Array(bibliography&.references).first.to_s
      return "" if result.blank?

      %(<p class="citation_style_#{label}">#{result}</p>).html_safe
    rescue StandardError => e
      Rails.logger.warn("Citeproc failed for #{style_id}: #{e}")
      ""
    end

    def load_style(style_id)
      CSL::Style.load(style_id)
    rescue StandardError
      CSL::Style.load("#{style_id}.csl")
    end

    def csl_item
      @csl_item ||= Citeproc::ItemService.build(document)
    end

    def null_citation
      { "NULL" => "<p>No citation available for this record</p>".html_safe }
    end
end
