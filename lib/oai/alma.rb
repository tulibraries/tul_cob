require 'rsolr'
require 'nokogiri'
require 'tempfile'
require 'fileutils'

module Oai
  module Alma
    def self.harvest
      oai_url = "https://sandbox01-na.alma.exlibrisgroup.com/view/oai/01TULI_INST/request?verb=ListRecords&set=blacklight&metadataPrefix=marc21"
      response = HTTParty.get(oai_url)

      tmp_path = File.join(Rails.root, 'tmp', 'alma', 'oai')
      FileUtils::mkdir_p tmp_path
      harvest_file = Tempfile.create(['alma-', '.xml'], tmp_path)
      harvest_file.write(response.body)
      harvest_file.path
    end

    def self.conform(harvest_filename)
      oai = Nokogiri::XML(File.open(harvest_filename))
      records = oai.xpath("//oai:record/oai:metadata/marc21:record", {'oai' => 'http://www.openarchives.org/OAI/2.0/', 'marc21' => "http://www.loc.gov/MARC21/slim"})
      collection_namespaces = {
        'xmlns' => 'http://www.loc.gov/MARC21/slim',
        'xmlns:xsi' => 'http://www.w3.org/2001/XMLSchema-instance',
        'xsi:schemaLocation' => 'http://www.loc.gov/MARC21/slim http://www.loc.gov/standards/marcxml/schema/MARC21slim.xsd'
      }

      marc_doc = Nokogiri::XML::Builder.new("encoding" => "UTF-8") do |xml|
        xml.collection(collection_namespaces) do |col|
          records.each do |rec|
            xml.record do
              xml.parent << rec.inner_html
            end
          end
        end
      end

      tmp_path = File.join(Rails.root, 'tmp', 'alma', 'marc')
      FileUtils::mkdir_p tmp_path
      marc_file = File.new(File.join(tmp_path, File.basename(harvest_filename)), "w")
      marc_file.write(marc_doc.to_xml)
      marc_file.path
    end
  end
end

