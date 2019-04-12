#! /usr/bin/env ruby
# frozen_string_literal: true

require "nokogiri"
doc = File.open("./alma_bibs_boundwith.xml") { |f| Nokogiri::XML(f) }
wf = File.open("child_mms_ids.txt", "w")

wf << "MMSID\n"

doc.xpath("//datafield[@tag='774']//subfield[@code='w']")
  .map(&:text).sort.uniq
  .each { |id| wf << id + "\n" }

wf.close
