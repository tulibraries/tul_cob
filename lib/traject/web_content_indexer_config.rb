# frozen_string_literal: true

$:.unshift "./lib" if !$:.include?("./lib")
require "traject_plus"
require "traject_plus/json_reader.rb"
require "traject_plus/macros"
require "traject_plus/macros/json"
require "traject/macros/custom"
require "nokogiri"

extend TrajectPlus::Macros
extend TrajectPlus::Macros::JSON
extend Traject::Macros::Custom

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

WEBSITE_TYPES = /building|space|service|policy|collection/i

to_field "id", ->(rec, acc) {
  acc << "#{rec['type']}_#{rec['id']}"
}

to_field "web_type_pivot_facet", ->(rec, acc) {
  if rec.fetch("type").match(WEBSITE_TYPES)
    acc << "Website"
  end

  if rec.fetch("type") == "person"
    acc << "People/Staff Directory"
  end

  if rec.fetch("type") == "event" || rec.fetch("type") == "exhibition"
    acc << "Events and Exhibits"
  end

  if rec.fetch("type") == "finding_aid"
    acc << "Finding Aids"
  end
}

# Should we pluralize types?  How to do that for only types and not other info in facet?
to_field "web_content_type_facet", ->(rec, acc) {
  if rec.fetch("type").match(WEBSITE_TYPES)
    acc << rec.fetch("type")
  end

  if rec.fetch("type") == "person"
    specialties = rec.dig("attributes", "specialties")
    acc.replace(specialties.reject(&:empty?).map { |specialty| specialty }) unless specialties.nil?
  end

  if rec.fetch("type") == "event" || rec.fetch("type") == "exhibition"
    acc << rec.fetch("type")
  end

  if rec.fetch("type") == "finding_aid"
    subjects = rec.dig("attributes", "subject")
    acc.replace(subjects.reject(&:empty?).map { |subject| subject }) unless subjects.nil?

  end
}

to_field "web_title_display", extract_json("$.attributes.label")

# Same issue as descriptions.  Should only appear for people, not buildings.
to_field "web_phone_number_display", extract_json("$.attributes.phone_number")

to_field "web_photo_display", extract_json("$.attributes.thumbnail_image")
to_field "web_subject_display", extract_json("$.attributes.subject")
to_field "web_base_url_display", extract_json("$.attributes.base_url")

# This attribute isn't displayed for every entity that contains it
# What is the best way to suppress this for entities that don't use it?
to_field "web_description_display", ->(rec, acc) {
  if rec.dig("attributes", "description")
    acc << Nokogiri::HTML(rec.dig("attributes", "description")).text
  end
}, &truncate(100)

#person specific
to_field "web_job_title_display", extract_json("$.attributes.job_title")
to_field "web_email_address_display", extract_json("$.attributes.email_address")
to_field "web_specialties_display", extract_json("$.attributes.specialties")

#group specific
to_field "web_group_type_display", extract_json("$.attributes.group_type")

#highlight specific
to_field "web_blurb_display", extract_json("$.attributes.blurb")
to_field "web_tags_display", extract_json("$.attributes.tags")
to_field "web_link_display", extract_json("$.attributes.link")

# we need update times from the JSON responses.
# Ticketed in MAN-242
# It seems that this work has been done, not sure if anything here needs
# to be altered in order for it to work
each_record do |record, context|
  context.output_hash["record_update_date"] = [ Time.now.to_s ]
end
