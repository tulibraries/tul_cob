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

  def get_request_level(partial = nil)
    if partial == "asrs"
      # This conditional still needs to be refactored.
      if AlmawsController::helpers.asrs_items(@items).present? && AlmawsController::helpers.non_asrs_items(@items).present?
        "item"
      else
        has_description?(@items) ? "item" : "bib"
      end
    else
      has_description?(@items) ? "item" : "bib"
    end
  end

  def asrs_request_level
    get_request_level("asrs")
  end

  def pickup_locations
    pickup_location_codes&.collect { |library_code| { library_code => library_name_from_short_code(library_code) } }
  end

  def asrs_pickup_locations
    ["MAIN", "AMBLER", "GINSBURG", "PODIATRY", "HARRISBURG"]&.collect { |library_code| { library_code => library_name_from_short_code(library_code) } }
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

    location_hash = @items.reduce({}) { |libraries, item|
      desc = item.description
      campus = self.determine_campus(item.library)
      removals = []
      international_pickup = []

      if libraries[desc].present?
        removals << item.library if remove_by_campus(campus) unless campus == :MAIN
        libraries[desc] -= removals
      elsif item.library == "JAPAN" || item.library == "ROME"
        international_pickup << item.library
        libraries[desc] = international_pickup
      else
        removals << item.library if remove_by_campus(campus) unless campus == :MAIN
        libraries[desc] = pickup_locations - removals
      end

      libraries
    }
    location_hash.transform_values do |v|
      v.reduce({}) { |acc, library_code|
        acc.merge!(library_name_from_short_code(library_code) => library_code)
      }
    end
  end

  def equipment_locations
    pickup_locations = []
    @items.each do |item|
      if item.circulation_policy == "Equipment"
        pickup_locations << item.item_data.fetch("library")
      end
    end
    pickup_locations
  end

  def booking_locations
    pickup_location = @items.map { |item|
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

  def asrs_material_types_and_descriptions
    if asrs_request_level == "item"
      asrs_items = @items.select { |item| item.library == "ASRS" && item.in_place? }
      combine_material_types_and_descriptions(asrs_items)
    else
      material_types_and_descriptions || ""
    end
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
