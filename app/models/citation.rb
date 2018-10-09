# frozen_string_literal: true

class Citation
  def initialize(document, formats = [])
    @document = document
    @formats = formats
  end

  def citable?
    field.present?
  end

  def citations
    return null_citation if return_null_citation?
    return all_citations if all_formats_requested?
    all_citations.select do |format, _|
      desired_formats.include?(format)
    end
  end

  class << self
    def grouped_citations(all_citations)
      citations = all_citations.each_with_object({}) do |cites, hash|
        cites.each do |format, citation|
          hash[format] ||= []
          hash[format] << citation
        end
      end
    end
  end

  private

    attr_reader :document, :formats

    def return_null_citation?
      all_citations.blank? || (field.blank? && all_citations.blank?)
    end

    def element_is_citation?(element)
      element.attributes &&
        element.attributes["class"] &&
        element.attributes["class"].value =~ /^citation_style_/i
    end

    def all_formats_requested?
      desired_formats == ["ALL"]
    end

    def all_citations
      @all_citations ||= begin
        citation_hash = {}
        citation_hash.merge!(citations_from_oclc_response) if field.present?
        citation_hash
      end
    end

    def citations_from_oclc_response
      Nokogiri::HTML(response).css("p").each_with_object({}) do |element, hash|
        next unless element_is_citation?(element)
        element.attributes["class"].value[/^citation_style_(.*)$/i]
        hash[Regexp.last_match[1].upcase] = element.to_html.html_safe
      end
    end

    def response
      @response ||= begin
        HTTParty.get(api_url)
        rescue HTTParty::Error::ConnectionFailed, HTTParty::TimeoutError => e
          Rails.logger.warn("HTTP GET for #{api_url} failed with #{e}")
          ""
      end
    end

    def api_url
      "#{base_url}/#{field}?cformat=all&wskey=#{api_key}"
    end

    def field
      field = Array(document["oclc_number_display"]).try(:first)
    end

    def desired_formats
      return config["citation_formats"].map(&:upcase) unless formats.present?
      formats.map(&:upcase)
    end

    def base_url
      config["base_url"]
    end

    def api_key
      config["apikey"]
    end

    def config
      Rails.configuration.oclc
    end

    def null_citation
      { "NULL" => "<p>No citation available for this record</p>".html_safe }
    end
end
