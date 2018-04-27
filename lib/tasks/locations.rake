# frozen_string_literal: true

require "nokogiri"
require "yaml"

namespace :locations do
  desc "Import locations for each library"
  task import: :environment do

    library_response = HTTParty.get("https://api-na.hosted.exlibrisgroup.com/almaws/v1/conf/libraries?apikey=#{apikey}")
    library = library_response["libraries"]["library"]
    library_list = []
    location_list = {}
    library.each do |lib|
      library_list << lib["code"] unless lib["code"] == "EMPTY"
    end

    library_list.each do |code|
      location_response = HTTParty.get("https://api-na.hosted.exlibrisgroup.com/almaws/v1/conf/libraries/#{code}/locations?apikey=#{apikey}")
      locations = location_response["locations"]["location"]
      location_list[code] =  {}
      locations.each do |l|
        if code == "RES_SHARE"
          name = l.fetch("name", "").to_s
          location_list[code][l["code"]] = (name.empty?) ? "Location information not available" : name
        elsif code == "KARDON"
          external_name = l.fetch("external_name", "").to_s
          location_list[code][l["code"]] = (external_name.empty?) ? "Location information not available" : "Remote Storage, #{external_name}"
        else
          external_name = l.fetch("external_name", "").to_s
          location_list[code][l["code"]] = (external_name.empty?) ? "Location information not available" : external_name
        end
      end
    end

    location_list
    file_path = "#{Rails.root}/config/locations.yml"
    File.open(file_path, "w+") do |file|
      file.write(
        location_list.to_yaml)
    end
  end

  private

    def self.apikey
      Alma.configuration.apikey
    end
end
