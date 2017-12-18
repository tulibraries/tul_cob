#! /usr/bin/env ruby

# Retieves a record from a MARC XML file given the file containing the record and its ID
# example: bin/get_record.rb sample_data/alma-bibs.xml 991014318129703811
require 'nokogiri'

# Fetch XML file

file_path = ARGV[0]
search_id = ARGV[1]

doc = Nokogiri::XML(File.open(file_path))
doc.remove_namespaces!

doc.xpath('//record//metadata//record').each do |record|
  id = record.xpath("controlfield[@tag='001']").text
  if (id == search_id)
    newxml = Nokogiri::XML(record.to_xml)  
    filename = "tmp/data/record-#{search_id}.xml"
    File.write(filename, newxml.to_xml) 
    break
  end
end
