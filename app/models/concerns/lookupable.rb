# frozen_string_literal: true

module Lookupable
  def library_name_from_short_code(library_code)
    if !library_name = Rails.configuration.libraries[library_code]
      Honeybadger.notify("Missing library name configuration for: #{library_code}")
      library_name = library_code
    end
    library_name
  end

  def location_name_from_short_codes(location_code, library_code = nil)
    Rails.configuration.locations.dig(library_code, location_code) || location_code
  end
end
