# frozen_string_literal: true

class RequestData
  include Lookupable

  attr_reader :request_level
  attr_reader :pickup_location_codes

  def initialize(bib_items, params = nil)
    @items = bib_items
    @request_level = params ? params[:request_level] : get_request_level
    @pickup_location_codes = params ? params[:pickup_location]&.split(",") : valid_pickup_locations
  end

  def item_holding_ids
    @items.collect { |item| [item["holding_data"]["holding_id"], item["item_data"]["pid"]] }.to_h
  end

  def item_holding_ids_backup
    item_pids = @items.collect { |item| item["item_data"]["pid"] }
    @items.collect { |item| [item["holding_data"]["holding_id"], item_pids.first] }.to_h
  end

  def get_request_level(partial = nil)
    has_description?(@items) ? "item" : "bib"
  end

  def pickup_locations
    pickup_location_codes&.collect { |library_code| { library_code => library_name_from_short_code(library_code) } }
  end

  def valid_pickup_locations
    libraries = available_libraries
    pickup_locations = default_pickup_locations

    if libraries.any?
      removals = []
      libraries.each do |lib|
        campus = determine_campus(lib)
        next if lib == "MAIN"
        next if [lib, campus] == ["ASRS", :MAIN]
        removals << lib if remove_by_campus(campus).include?(lib)
        removals
      end
      pickup_locations -= removals
      if (libraries & ["ROME", "JAPAN"]).present?
        if libraries.size == 1 || libraries.sort == ["JAPAN", "ROME"]
          pickup_locations = libraries
        else
          pickup_locations << libraries.select { |lib| lib == "ROME" || lib == "JAPAN" }
        end
      end
    end
    pickup_locations << reserve_or_reference
    pickup_locations.flatten
  end

  def reserve_or_reference
    pickup_locations = []

    current_locations = @items.group_by(&:library).collect { |k, v|
      v.map { |item|
        [item.item_data.dig("location", "value")]
      }.flatten }
    library_and_locations = @items.group_by(&:library).keys.zip(current_locations).to_h

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

  def item_level_locations
    pickup_locations = default_pickup_locations

    @items.group_by(&:description).each_with_object({}) do |(desc, items), result|
      libraries = items.map(&:library).uniq
      
      mapped_libraries = libraries.map { |lib| lib == "ASRS" ? "MAIN" : lib }.uniq
      allowed_libraries = []

      mapped_libraries.each do |library|
        campus = determine_campus(library)

        if library == "JAPAN" || library == "ROME"
          allowed_libraries |= [library]
        else
          allowed_libraries |= pickup_locations if (allowed_libraries - ["JAPAN", "ROME"]).empty?
          allowed_libraries -= remove_by_campus(campus) unless campus == :MAIN
        end
      end

      item_pickup_locations = allowed_libraries.reject(&:blank?)

      result[desc] = item_pickup_locations.each_with_object({}) do |library_code, acc|
        acc[library_name_from_short_code(library_code)] = library_code
      end
    end
  end

  def equipment_locations
    pickup_locations = []
    @items.each do |item|
      if item.circulation_policy == "Equipment" || item.library == "DSC"
        pickup_locations << item.item_data.fetch("library")
      end
    end
    pickup_locations
  end

  def booking_locations
    @items.map { |item|
      campus = determine_campus(item.library)
      if campus == :MAIN
        ["MAIN", "Charles Library"]
      else
        nil
      end
    }.uniq.compact
  end

  def material_types_and_descriptions
    combine_material_types_and_descriptions(@items)
  end

  def material_types
    material_types = @items.map { |item| item.physical_material_type unless item.physical_material_type["value"] == "" }

    if material_types.any?
      material_types.each do |material_type|
        material_type
      end
    end
    material_types.uniq.compact
  end

  def descriptions
    descriptions = @items.map(&:description)

    if descriptions.any?
      descriptions.each do |description|
        description
      end
    end
    descriptions.uniq.sort
  end

    private

      def default_pickup_locations
        ["MAIN", "AMBLER", "GINSBURG", "PODIATRY", "HARRISBURG"]
      end

      def available_libraries
        @items.group_by(&:library).select { |library, items| items.any?(&:in_place?) }.keys
      end

      def determine_campus(item)
        case item
        when "PRESSER", "MAIN", "ASRS"
          :MAIN
        when "GINSBURG"
          :HSL
        when "AMBLER", "PODIATRY", "HARRISBURG", "JAPAN", "ROME"
          item.to_sym
        else
          :OTHER
        end
      end

      def remove_by_campus(campus)
        case campus
        when :MAIN
          ["MEDIA", "PRESSER", "MAIN", "ASRS"]
        when :AMBLER
          ["AMBLER"]
        when :HSL
          ["GINSBURG"]
        when :PODIATRY
          ["PODIATRY"]
        when :HARRISBURG
          ["HARRISBURG"]
        else
          []
        end
      end

      def combine_material_types_and_descriptions(items)
        types_and_descriptions = items.map { |item|
          Hash[item.physical_material_type["desc"], [item.description]] unless item.physical_material_type["value"] == ""
        }.uniq.compact

        types_and_descriptions.reduce({}) do |acc, rec|
          key, value = rec.to_a.flatten
          if acc[key]
            acc[key] << value
            acc[key].uniq!
          else
            acc[key] = [value]
          end
          acc
        end.to_a
      end

      def has_description?(items)
        items.map { |item| item.description }.reject(&:blank?).present?
      end
end
