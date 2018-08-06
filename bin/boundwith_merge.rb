#! /usr/bin/env ruby
require 'nokogiri'

parentmarcfile = "boundwith.xml"
parentdoc = File.open(parentmarcfile) { |f| Nokogiri::XML(f) }
#parentrecordids = parentdoc.xpath("//xmlns:subfield[@tag=w]")
# parentrecordids.each do |pr|
#   puts pr.text
# end

### this file doesn't contain a namespace, so no xmlns in the xpath queries
childmarcfile = "alma_bibs_boundwith_children_2018080216_8286523500003811_new.xml"
childdoc = File.open(childmarcfile) { |f| Nokogiri::XML(f) }

parentrecords = parentdoc.xpath("//xmlns:record")
parentrecords.each do |pr|
  parentid = pr.xpath("xmlns:controlfield[@tag='001']").text
  datafields = pr.xpath("xmlns:datafield[@tag='774']")
  datafields.each do |df|
    childids = df.xpath("xmlns:subfield[@code='w']")
    childids.each do |ci|
      childid = ci.text
      childrecord = childdoc.xpath("collection/record/controlfield[@tag='001'][contains(text(),'#{childid}')]")
      if !childrecord.to_s.empty?
        childrecord = childrecord[0].parent
        parentITM = pr.xpath("xmlns:datafield[@tag='ITM']")
        if !parentITM.to_s.empty?
          childrecord.add_child(parentITM[0].clone())
        else
          puts "Parent " + parentid.to_s + " does not have an ITM field for its child " + childid.to_s
        end
      else
        puts "Child ID not found: " + childid.to_s
      end
    end
  end
end

childdoc.remove_namespaces!
childdoc.children[0].add_namespace(nil, "http://www.loc.gov/MARC21/slim" )
boundwith_merged_file = "boundwith_merged.xml"
File.write(boundwith_merged_file, childdoc)
