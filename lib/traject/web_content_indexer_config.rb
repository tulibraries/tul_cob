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

# Seems like Manifold JSON should define a label attribute?
# https://tulibdev.atlassian.net/browse/MAN-245
to_field "title_display", ->(rec, acc) {
  title_field = {
    "person" => ["attributes", "name"],
    "building" => ["attributes", "name"],
    "event" => ["attributes", "title"]
  }

  type = rec.fetch("type")
  acc << rec.dig(*title_field[type])
}

#person specific
to_field "job_title_display", extract_json("$.attributes.job_title")

to_field "description_display", ->(rec, acc) {
  if rec.dig("attributes", "description")
    acc << Nokogiri::HTML(rec.dig("attributes", "description")).text
  end
}

to_field "phone_number_display", extract_json("$.attributes.phone_number")

#to_field "photo_display", extract_json("$.attributes.thumbnail_image")
# Manifold JSONAPI needs standarized name for thumbnails
# https://tulibdev.atlassian.net/browse/MAN-244
to_field "photo_display", ->(rec, acc) {
  title_field = {
    "person" => ["attributes", "thumbnail_photo"],
    "building" => ["attributes", "thumbnail_photo"],
    "event" => ["attributes", "thumbnail_image"]
  }

  type = rec.fetch("type")
  acc << rec.dig(*title_field[type])
}


to_field "url_display", extract_json("$.links.self")
# we need update times from the JSON responses.
# Ticketed in MAN-242
each_record do |record, context|
  context.output_hash["record_update_date"] = [ Time.now.to_s ]
end
