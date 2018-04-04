# frozen_string_literal: true

require "nokogiri"
require "yaml"

namespace :locations do
  desc "Import locations for each library"
  task :import => :environment do

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
        location_list[code][l["code"]] = l.fetch("external_name") if !l.fetch("external_name").nil?
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
