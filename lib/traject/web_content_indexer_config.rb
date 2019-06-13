# frozen_string_literal: true

require "traject_plus"
require "traject_plus/json_reader.rb"
require "traject_plus/macros"
require "traject_plus/macros/json"
require "nokogiri"

extend TrajectPlus::Macros
extend TrajectPlus::Macros::JSON

solr_config = YAML.load_file("config/blacklight.yml")[(ENV["RAILS_ENV"] || "development")]

solr_url = ERB.new(solr_config["web_content_url"]).result

def truncate(max = 300)
  Proc.new do |rec, acc|
    acc.map! { |s| s.length > max ? s[0...max] + " ..." : s unless s.nil? }
  end
end

settings do
  provide "reader_class_name", "TrajectPlus::JsonReader"
  provide "solr_writer.commit_timeout", (15 * 60)
  provide "solr.url", solr_url
  provide "solr_writer.commit_on_close", "false"

  # set this to be non-negative if threshold should be enforced
  provide "solr_writer.max_skipped", -1
end

to_field "id", ->(rec, acc) {
  acc << "#{rec['type']}_#{rec['id']}"
}

to_field "web_category_facet", extract_json("$.type")
to_field "web_title_display", extract_json("$.attributes.label")
to_field "web_phone_number_display", extract_json("$.attributes.phone_number")
to_field "web_photo_display", extract_json("$.attributes.thumbnail_image")
to_field "web_url_display", extract_json("$.links.self")

to_field "web_description_display", ->(rec, acc) {
  if rec.dig("attributes", "description")
    acc << Nokogiri::HTML(rec.dig("attributes", "description")).text
  end
}, &truncate(100)

#person specific
to_field "web_job_title_display", extract_json("$.attributes.job_title")

# we need update times from the JSON responses.
# Ticketed in MAN-242
# It seems that this work has been done, not sure if anything here needs
# to be altered in order for it to work
each_record do |record, context|
  context.output_hash["record_update_date"] = [ Time.now.to_s ]
end
