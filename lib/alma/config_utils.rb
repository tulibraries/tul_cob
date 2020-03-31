# frozen_string_literal: true

module Alma
  # Holds some configuration utility for Alma API.
  # This class is not intended for public use.
  class ConfigUtils
    def self.load_notes(options = {})
      options ||= {}
      type = options.fetch(:type, @type) || "service"
      file = File.read(filename(type))
      JSON.parse(file)
    end

    def self.filename(type = "service")
      tmp_file = "tmp/#{type}_notes.json"
      fixture_file = "spec/fixtures/#{type}_notes.json"

      if File.exist? tmp_file
        tmp_file
      else
        fixture_file
      end
    end
  end
end
