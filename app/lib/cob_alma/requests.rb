# frozen_string_literal: true

module CobAlma
  module Requests
    def self.determine_campus(item)
      case item
      when "MAIN", "LAW", "MEDIA", "PRESSER"
        :MAIN
      when "AMBLER"
        :AMBLER
      when "GINSBURG"
        :HSL
      when "PODIATRY"
        :PODIATRY
      when "HARRISBURG"
        :HARRISBURG
      else
        :OTHER
      end
    end

    def self.possible_pickup_locations
      #Make an array on only items that can request items
      ["MAIN", "MEDIA", "AMBLER", "GINSBURG", "PODIATRY", "HARRISBURG"]
    end

    def self.remove_by_campus(campus)
      case campus
      when :MAIN
        ["MAIN", "LAW", "MEDIA", "PRESSER"]
      when :AMBLER
        ["AMBLER"]
      when :HSL
        ["GINSBURG"]
      when :PODIATRY
        ["PODIATRY"]
      when :HARRISBURG
        ["HARRISBURG"]
      when :OTHER
        []
      end
    end

    def self.avail_locations(items_list)
      avail_locations = items_list.select { |k, v|
        v.any?(&:in_place?) }.keys
    end

    def self.valid_pickup_locations(items_list)
      pickup_locations = self.possible_pickup_locations
      libraries = self.avail_locations(items_list)

      if libraries.any?
        libraries.each do |lib|
          campus = self.determine_campus(lib)
          pickup_locations -= remove_by_campus(campus)
        end
      end
      pickup_locations << self.reserve_or_reference(items_list)
      pickup_locations
    end

    def self.item_level_locations(items_list)
      pickup_locations = self.possible_pickup_locations

      items_list.all.reduce({}) { |libraries, item|
        desc = item.description
        campus = determine_campus(item.library)

        if libraries[desc].present?
          libraries[desc] -= remove_by_campus(campus)
        else
          libraries[desc] = pickup_locations - remove_by_campus(campus)
        end

        libraries
      }
    end

    def self.reserve_or_reference(items_list)
      pickup_locations = []
      current_locations = items_list.collect { |k, v|
        v.map { |item|
          [item.item_data.dig("location", "value")]
        }.flatten }
      library_and_locations = items_list.keys.zip(current_locations).to_h

      if library_and_locations.length > 1
        reserve_or_reference = library_and_locations.select { |k, v| v.all? { |i| i == "reserve" || i == "reference" } }
        not_reserve_or_reference = library_and_locations
          .select { |k, v| v.all? { |i| i != "reserve" } }
          .select { |k, v| v.all? { |i| i != "reference" } }

        if reserve_or_reference.present? && not_reserve_or_reference.present?
          pickup_locations << reserve_or_reference.keys
        end
      end
      pickup_locations.flatten
    end

    def self.equipment(items_list)
      pickup_locations = []
      items_list.each do |item|
        if item.circulation_policy == "Equipment"
          pickup_locations << item.item_data.fetch("library")
        end
      end
      pickup_locations
    end

    def self.descriptions(items_list)
      descriptions = items_list.all.map(&:description)
      if descriptions.any?
        descriptions.each do |desc|
          desc
        end
      end
      descriptions.reject(&:empty?)
    end

    def self.booking_location(items_list)
      pickup_library = items_list.map { |item| [item.library, item.library_name] }
      pickup_library.uniq
    end

    def self.physical_material_type(items_list)
      material_types = items_list.map { |item| item["item_data"]["physical_material_type"] }

      if material_types.any?
        material_types.each do |material|
          material
        end
      end
      material_types.uniq
    end

    def self.item_holding_ids(items_list)
      items_list.collect { |item| [item["holding_data"]["holding_id"], item["item_data"]["pid"]] }.to_h
    end
  end
end
