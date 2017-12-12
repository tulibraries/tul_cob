#! /usr/bin/env ruby

# Searches for a file containing an XML record with the desired datatype.
# Outputs the URL in LibQA to the matching record
# Outputs the command to enter to create an XML file from the record
# Use: bin/find_xml.rb book file(s)
# example: bin/find_xml.rb computer_file ../sample_data/almadata.xml
#          bin/find_xml.rb computer_file ../sample_data/alma*.xml (for multiple files)

require 'nokogiri'
require "traject"
require 'traject/macros/marc_format_classifier'

require 'pry'

# Fetch XML file

def extract_by_type(file_path, data_type)
  
  doc = Nokogiri::XML(File.open(file_path))
  record_ids = find_by_type(doc, data_type)

  record_ids.each do |id|
    puts "URL: http://libqa.library.temple.edu/catalog/catalog/#{id}"
    puts "Command: bin/get_record.rb #{file_path} #{id}"
  end
end

def find_by_type(doc, search_type)
  qualifier_bis = ['b', 'i', 's']
  qualifier_fmv = ['f', 'm', 'v']
  leader6a_types = {
    'm': 'book',
    'd': 'database',
    'w': 'website'
  }
  leader6g_types = {
    'f': 'video',
    'm': 'video',
    'v': 'video'
  }
  leader6m_types = {
    'j': 'database',
    'h': 'audio',
    'a': 'data',
    'g': 'computer_file'
  }
  leader6_types = {
    'c': "score",
    'd': "score",
    'e': "map",
    'f': "map",
    'g': "video",
    'i': "audio",
    'j': "audio",
    'k': "visual",
    'm': "computer_file",
    'o': "kit",
    'p': "archival",
    'r': "object",
    't': "archival"
  } 
  
  doc.remove_namespaces!
  doc_ids = []
  doc.xpath('//record//metadata//record').each do |record|
    leader = record.xpath('leader').first.text
    cf008 = record.xpath("controlfield[@tag='008']").text
    cf006 = record.xpath("controlfield[@tag='006']").text
    id = record.xpath("controlfield[@tag='001']").text
    
    newxml = Nokogiri::XML(record.to_xml)  
  
    record_type = leader6_types.fetch(leader[6].to_sym) { |l6|
      case l6
      when :a
        if (qualifier_bis.include?(leader[7]))
          qualifier = cf008[21] ? cf008[21].to_sym : cf006[4].to_sym
          leader6a_types.fetch(qualifier) { |l6a| "serial" }
        else
          "book"
        end
      when :g
        leader6g_types[cf008[33].to_sym] if cf008[33]
      when :m
        leader6m_types[cf008[26].to_sym] if cf008[26]
      else
        'unknown'
      end
    }
    #puts "http://libqa.library.temple.edu/catalog/catalog/#{id} L6:#{leader[6]} L7:#{leader[7]} 008[21]:#{cf008[21]} 006[4]:#{cf006[4]} 008[33]:#{cf008[33]} 006[16]:#{cf006[16]} 008[26]:#{cf008[26]} 006[9]:#{cf006[9]} type:#{record_type}"
    doc_ids << id if (record_type == search_type)
  end
  doc_ids
end

search_term = ARGV[0]
file_list = ARGV[1..-1]
file_list.each do |file|
  extract_by_type(file, search_term)
end