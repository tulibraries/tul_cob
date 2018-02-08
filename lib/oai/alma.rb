# frozen_string_literal: true

require "rsolr"
require "nokogiri"
require "tempfile"
require "fileutils"

module Oai
  module Alma
    # Harvests OAI records from the alma server given an optional start and end time
    # Params
    # +time_range+:: Optinoal hash containing +:from+ (start) and +:to+ (end) time in ISO8601.
    def self.harvest(time_range)
      log_path = File.join(Rails.root, "log/fortytu.log")
      logger = Logger.new(log_path, 10, 1024000)

      from_time = time_range.fetch(:from) { "" }
      to_time = time_range.fetch(:to) { "" }
      oai_from = from_time.empty? ? from_time : "&from=#{from_time}"
      oai_to = to_time.empty? ? to_time : "&to=#{to_time}"
      oai_url = "https://sandbox01-na.alma.exlibrisgroup.com/view/oai/01TULI_INST/request?verb=ListRecords&set=blacklight&metadataPrefix=marc21" + oai_from + oai_to

      harvest_files = []

      begin
        loop do
          logger.info("Retrieving #{oai_url}")
          puts "Retrieving #{oai_url}"
          response = HTTParty.get(oai_url)
          oai = Nokogiri::XML(response.body)
          tmp_path = File.join(Rails.root, "tmp", "alma", "oai")
          FileUtils::mkdir_p tmp_path
          harvest_file = Tempfile.create(["alma-", ".xml"], tmp_path)
          harvest_file.write(response.body)
          harvest_files << harvest_file.path
          resumptionToken = oai.xpath("//oai:resumptionToken", "oai" => "http://www.openarchives.org/OAI/2.0/", "marc21" => "http://www.loc.gov/MARC21/slim")
          break if resumptionToken.empty?
          oai_url = "https://sandbox02-na.alma.exlibrisgroup.com/view/oai/01TULI_INST/request?verb=ListRecords&resumptionToken=#{resumptionToken.text}"
        end
      rescue => e
        logger.fatal("Fatal Error")
        logger.fatal(e)
      end
      harvest_files
    end

    def self.conform(harvest_filename)
      log_path = File.join(Rails.root, "log/fortytu.log")
      logger = Logger.new(log_path, 10, 1024000)
      begin
        oai = Nokogiri::XML(File.open(harvest_filename))
        updated_records = oai.xpath("//oai:record/oai:metadata/marc21:record",
                                    "oai" => "http://www.openarchives.org/OAI/2.0/",
                                     "marc21" => "http://www.loc.gov/MARC21/slim")
        deleted_records = oai.xpath('//oai:OAI-PMH/oai:ListRecords/oai:record[oai:header/@status="deleted"]',
                                    "oai" => "http://www.openarchives.org/OAI/2.0/",
                                     "marc21" => "http://www.loc.gov/MARC21/slim")
        logger.info("Delete Records found") unless deleted_records.empty?
        collection_namespaces = {
          "xmlns" => "http://www.loc.gov/MARC21/slim",
          "xmlns:xsi" => "http://www.w3.org/2001/XMLSchema-instance",
          "xsi:schemaLocation" => "http://www.loc.gov/MARC21/slim http://www.loc.gov/standards/marcxml/schema/MARC21slim.xsd"
        }

        unless updated_records.empty?
          update_filename = File.join(Rails.root, "tmp", "alma", "marc", File.basename(harvest_filename))
          write_updated(collection_namespaces, updated_records, update_filename)
        end

        unless deleted_records.empty?
          delete_filename = File.join(Rails.root, "tmp", "alma", "marc-delete", File.basename(harvest_filename))
          write_updated(collection_namespaces, deleted_records, delete_filename)
        end

      rescue => e
        logger.fatal("Fatal Error")
        logger.fatal(e)
      end

      { updated_records: updated_records, deleted_records: deleted_records }
    end

    def self.write_updated(collection_namespaces, records, filename)
      marc_doc = Nokogiri::XML::Builder.new("encoding" => "UTF-8") do |xml|
        xml.collection(collection_namespaces) do |col|
          records.each do |rec|
            xml.record do
              xml.parent << rec.inner_html
            end
          end
        end
      end
      FileUtils::mkdir_p File.dirname(filename)
      marc_file = File.new(filename, "w")
      marc_file.write(marc_doc.to_xml)
      marc_file.path
    end
  end
end
