require 'rsolr'
require 'nokogiri'
require 'tempfile'

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
      harvest_file = Tempfile.create(['alma-', '.xml'], './tmp')
      harvest_file.write(response.body)
      puts "Records harvested to: #{harvest_file.path}"
    end

    desc 'Conforms raw OAI MARC records to traject readable MARC records'
    task :conform, [:harvest_file] => :environment do |t, args|
      harvest_file = args[:harvest_file]
      converted_file = "converted.xml"

      oai = Nokogiri::XML(File.open(harvest_file))
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

      marc_file = Tempfile.create(['marc-', '.xml'], './tmp')
      marc_file.write(marc_doc.to_xml)
      puts "MARC file: #{marc_file.path}"

    end
  end
end
