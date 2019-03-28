# frozen_string_literal: true

require "traject_plus"
require "traject_plus/json_reader.rb"
require "traject_plus/macros"
require "traject_plus/macros/json"

extend TrajectPlus::Macros
extend TrajectPlus::Macros::JSON

solr_config = YAML.load_file("config/blacklight.yml")[(ENV["RAILS_ENV"] || "development")]

solr_url = ERB.new(solr_config["web_content_url"]).result

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

to_field "category_facet", extract_json("$.type")
# Can I do a select from one of multiple json fields?
to_field "title_display", extract_json("$.attributes.name")
to_field "title_display", extract_json("$.attributes.title")
# Can I do a select from one of multiple json fields?
to_field "description_display", extract_json("$.attributes.job_title")
to_field "description_display", extract_json("$.attributes.description")

to_field "phone_number_display", extract_json("$.attributes.phone_number")
to_field "photo_display", extract_json("$.attributes.thumbnail_image")

# we need update times from the JSON responses.
# Ticketed in MAN-242
each_record do |record, context|
  context.output_hash["record_update_date"] = [ Time.now.to_s ]
end
