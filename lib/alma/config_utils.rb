# frozen_string_literal: true

module Alma
  # Holds some configuration utility for Alma API.
  # This class is not intended for public use.
  class ConfigUtils
    def self.load_notes(options = {})
      options ||= {}
      type = options.fetch(:type, @type) || "service"
      path = options.fetch(:path, "tmp")
      file = File.read(filename_or_default(type, path))
      JSON.parse(file)
    end

    def self.fixture_filename(type = "service")
      "spec/fixtures/#{type}_notes.json"
    end

    def self.filename(type, path)
      "#{path}/#{type}_notes.json"
    end

    def self.filename_or_default(type = "service", path = "tmp")
      if File.exist? filename(type, path)
        filename(type, path)
      else
        fixture_filename(type)
      end
    end
  end
end
