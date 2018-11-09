# frozen_string_literal: true

module Alma
  # Holds some configuration utlity for Alma API.
  # This class is not intended for public use.
  class ConfigUtils
    def self.load_notes(options = {})
      options ||= {}
      type = options.fetch(:type, @type)
      filename = options.fetch(:filename, "spec/fixtures/#{type}_notes.json")

      file = File.read(filename)
      JSON.parse(file)
    end
  end
end
