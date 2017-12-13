#! /usr/bin/env ruby

# Searches for a file containing an XML record with the desired datatype.
# Outputs the URL in LibQA to the matching record
# Outputs the command to enter to create an XML file from the record
# Use: bin/find_xml.rb book file(s)
# example: bin/find_xml.rb computer_file ../sample_data/almadata.xml
#          bin/find_xml.rb computer_file ../sample_data/alma*.xml (for multiple files)

$LOAD_PATH.unshift File.expand_path("../../lib", __FILE__)
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
  
  marc_genre_leader   = Traject::TranslationMap.new("marc_genre_leader").to_hash
  marc_genre_007      = Traject::TranslationMap.new("marc_genre_007").to_hash
  marc_genre_008_21   = Traject::TranslationMap.new("marc_genre_008_21").to_hash
  marc_genre_008_26   = Traject::TranslationMap.new("marc_genre_008_26").to_hash
  marc_genre_008_33   = Traject::TranslationMap.new("marc_genre_008_33").to_hash
  resource_type_codes = Traject::TranslationMap.new("resource_type_codes").to_hash
  
  doc.remove_namespaces!
  doc_ids = []
  doc.xpath('//record//metadata//record').each do |record|
  #doc.xpath('//record').each do |record|
    leader = record.xpath('leader').first.text
    cf008 = record.xpath("controlfield[@tag='008']").text
    cf006 = record.xpath("controlfield[@tag='006']").text
    id = record.xpath("controlfield[@tag='001']").text
    
    newxml = Nokogiri::XML(record.to_xml) 
    
    results = marc_genre_leader.fetch(leader[6..7]) { # Leaders 6 and 7
      marc_genre_leader.fetch(leader[6]) { # Leader 6
        'unknown'
      }
    }
  
    # Additional qualifiers
    
    case results
    when "serial" # Serial component, Integrating resource, Serial
      additional_qualifier = marc_genre_008_21.fetch(cf008[21]) { # Controlfield 008[21]
        cf006.nil? ? "serial" : marc_genre_008_21.fetch(cf006[4]) {  # Controlfield 006[4]
            "serial"
        }
      }
    when "video" # Projected medium
      additional_qualifier = marc_genre_008_33.fetch(cf008[33]) { # Controlfield 008[33]
        cf006.nil? ? "visual" : marc_genre_008_33.fetch(cf006[16]) { # Controlfield 006[16]
          "visual"
        }
      }
    when "computer_file"
      additional_qualifier = marc_genre_008_26.fetch(cf008[26]) { # Controlfield 008[26]
        cf006.nil? ? "computer_file" : marc_genre_008_26.fetch(cf006[9]) { # Controlfield 006[9]
            "computer_file"
        }
      }
    else # Everything else
      additional_qualifier = nil
    end
    results = additional_qualifier if additional_qualifier
    
    #puts "http://libqa.library.temple.edu/catalog/catalog/#{id} L6:#{leader[6]} L7:#{leader[7]} 008[21]:#{cf008[21]} 006[4]:#{cf006[4]} 008[33]:#{cf008[33]} 006[16]:#{cf006[16]} 008[26]:#{cf008[26]} 006[9]:#{cf006[9]} type:#{record_type}"
    doc_ids << id if (results == search_type)
  end
  doc_ids
end

search_term = ARGV[0]
file_list = ARGV[1..-1]
file_list.each do |file|
  extract_by_type(file, search_term)
end