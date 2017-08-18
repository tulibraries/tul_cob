require 'rsolr'
require 'nokogiri'

namespace :fortytu do

  desc 'Posts fixtures to Solr'
  task :ingest, [:marc_file] => :environment do |t, args|
    `traject -c app/models/traject_indexer.rb #{args[:marc_file]}`
    `traject -c app/models/traject_indexer.rb -x commit`
  end

  desc 'Delete fixtures from Solr'
  task :clean => :environment do
    solr = RSolr.connect :url => Blacklight.connection_config[:url]
    solr.update data: '<delete><query>*:*</query></delete>'
    solr.update data: '<commit/>'
  end

  namespace :oai do
    desc 'Harvests OAI MARC records from Alma'
    task :harvest do
      oai_url = "https://sandbox01-na.alma.exlibrisgroup.com/view/oai/01TULI_INST/request?verb=ListRecords&set=blacklight&metadataPrefix=marc21"
      output_file = "harvest.xml"
      output_file_mode = "w"
      response = HTTParty.get(oai_url)
      File.open(output_file,  output_file_mode) do |f|
        f.write(response.body)
      end
    end

    desc 'Conforms raw OAI MARC records to traject readable MARC records'
    task :conform do
      harvest_file = "harvest.xml"
      converted_file = "converted.xml"
      oai = Nokogiri::XML(File.open(harvest_file))
      records = oai.xpath("//oai:record/oai:metadata/marc21:record", {'oai' => 'http://www.openarchives.org/OAI/2.0/', 'marc21' => "http://www.loc.gov/MARC21/slim"})
      binding.pry
      collection_attributes = {
        'xmlns' => 'http://www.loc.gov/MARC21/slim',
        'xmlns:xsi' => 'http://www.w3.org/2001/XMLSchema-instance',
        'xsi:schemaLocation' => 'http://www.loc.gov/standards/marcxml/schema/MARC21slim.xsd'
      }
      collection = "<collection xmlns='http://www.loc.gov/MARC21/slim' " +
                   "xmlns:xsi='http://www.w3.org/2001/XMLSchema-instance' " +
                   "xsi:schemaLocation='http://www.loc.gov/MARC21/slim " +
                   "http://www.loc.gov/standards/marcxml/schema/MARC21slim.xsd'>" +
                   "#{records}</collection>"
      marc_doc = Nokogiri::XML collection

      File.open(converted_file, 'w') { |f| f.write marc_doc.to_xml }

      # collection = Nokogiri::XML::Node.new "collection", ""
    end
  end
end
