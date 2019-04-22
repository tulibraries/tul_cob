# frozen_string_literal: true

module BlacklightMarcHelper
  # This method is brought over from the Blacklight Marc gem so that we can include the links for journals
  def refworks_export_url(params = {})
    "http://www.refworks.com/express/expressimport.asp?vendor=#{CGI.escape(params[:vendor] || application_name)}&filter=#{CGI.escape(params[:filter] || "MARC Format")}&encoding=65001" + (("&url=#{CGI.escape(params[:url])}" if params[:url]) || "")
  end

  # Overrides the original method in Blacklight Marc so that we only use this link for catalog items
  def refworks_solr_document_path(opts = {})
    return if !opts[:id]

    case controller_name
    when "catalog"
      refworks_export_url(url: solr_document_url(opts[:id], format: :refworks_marc_txt))
    when "journals"
      refworks_export_url(url: solr_journal_document_url(opts[:id], format: :refworks_marc_txt))
    end
  end

  # puts together a collection of documents into one refworks export string
  def render_refworks_texts(documents)
    val = ""
    documents.each do |doc|
      if doc.exports_as? :refworks_marc_txt
        val += doc.export_as(:refworks_marc_txt) + "\n"
      end
    end
    val
  end
end
