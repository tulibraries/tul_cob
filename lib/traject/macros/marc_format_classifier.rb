# frozen_string_literal: true

module Traject
  module Macros
    # To use the marc_format macro, in your configuration file:
    #
    #     require "traject/macros/marc_format_classifier"
    #     extend Traject::Macros::MarcFormats
    #
    #     to_field "format", marc_formats
    #
    # See also MarcClassifier which can be used directly for a bit more
    # control.
    module MarcFormats
      # very opionated macro that just adds a grab bag of format/genre/types
      # from our own custom vocabulary, all into one field.
      # You may want to build your own from MarcFormatClassifier functions instead.

      def marc_formats
        lambda do |record, accumulator|
          accumulator.concat Traject::Macros::MarcFormatClassifier.new(record).formats
        end
      end

      def four_digit_year(field)
        year = field.to_s.match(/[0-9]{4}/).to_s
        year unless year.empty?
      end
    end


    # A tool for classifiying MARC records according to format/form/genre/type,
    # just using our own custom vocabulary for those things.
    #
    # used by the `marc_formats` macro, but you can also use it directly
    # for a bit more control.
    class MarcFormatClassifier
      attr_reader :record

      def initialize(marc_record)
        @record = marc_record
      end

      # A very opinionated method that just kind of jams together
      # all the possible format/genre/types into one array of 1 to N elements.
      #
      # If no other values are present, the default value "Other" will be used.
      #
      # See also individual methods which you can use you seperate into
      # different facets or do other custom things.
      def formats(options = {})
        options = { default: "Other" }.merge(options)

        formats = []

        formats.concat genre

        # If it"s a Dissertation, we decide it"s NOT a book
        if thesis?
          formats.delete("Book")
          formats << "Dissertation/Thesis"
        end

        formats << "Conference Proceeding" if proceeding?
        formats << "Government Document" if govdoc?
        formats << options[:default] if formats.empty?

        return formats
      end



      # Returns 1 or more values in an array from:
      # Book; Journal/Newspaper; Musical Score; Map/Globe; Non-musical Recording; Musical Recording
      # Image; Software/Data; Video/Film
      #
      # Uses leader byte 6, leader byte 7.
      #
      # Gets actual labels from marc_genre_leader translation maps,
      # so you can customize labels if you want.
      #
      # Reference: https://tulibdev.atlassian.net/wiki/spaces/SAD/pages/22839300/Data+Mappings+Displays+Facets+Search#DataMappings(Displays,Facets,Search)-ResourceTypeMappings
      def genre
        marc_genre_leader   = Traject::TranslationMap.new("marc_genre_leader").to_hash
        marc_genre_leader_7 = Traject::TranslationMap.new("marc_genre_leader_7").to_hash
        marc_genre_008_21   = Traject::TranslationMap.new("marc_genre_008_21").to_hash
        marc_genre_008_26   = Traject::TranslationMap.new("marc_genre_008_26").to_hash
        marc_genre_008_33   = Traject::TranslationMap.new("marc_genre_008_33").to_hash
        resource_type_codes = Traject::TranslationMap.new("resource_type_codes").to_hash

        # Leader Field

        leader = record.leader

        # Control Fields

        cf006 = record.find_all { |f| f.tag == "006" }.first
        cf008 = record.find_all { |f| f.tag == "008" }.first

        # Without qualifiers

        results = marc_genre_leader.fetch(record.leader[6..7]) { # Leaders 6 and 7
          marc_genre_leader.fetch(record.leader[6]) { # Leader 6
            "unknown"
          }
        }

        # Additional qualifiers
        additional_qualifier = nil
        case results
        when "serial" # Serial component, Integrating resource, Serial
          additional_qualifier = marc_genre_008_21.fetch(cf008.value[21], nil) unless cf008.nil? # Controlfield 008[21]
          additional_qualifier ||= marc_genre_008_21.fetch(cf006.value[4], nil) unless cf006.nil?  # Controlfield 006[4]
          additional_qualifier ||= "serial"
        when "video" # Projected medium
          additional_qualifier = marc_genre_008_33.fetch(cf008.value[33], nil) unless cf008.nil? # Controlfield 008[33]
          additional_qualifier ||= marc_genre_008_33.fetch(cf006.value[16], nil) unless cf006.nil? # Controlfield 006[16]
          additional_qualifier ||= "visual"
        when "computer_file"
          additional_qualifier = marc_genre_008_26.fetch(cf008.value[26], nil) unless cf008.nil? # Controlfield 008[26]
          additional_qualifier ||= marc_genre_008_26.fetch(cf006.value[9], nil) unless cf006.nil? # Controlfield 006[9]
          if additional_qualifier == "leader_7" # replace if we must take the additional qualifier from leader_7
            additional_qualifier = marc_genre_leader_7.fetch(record.leader[7], nil) unless record.leader[7].nil?
          end
          additional_qualifier ||= "computer_file"
        else # Everything else
        end
        results = additional_qualifier if additional_qualifier

        [results].flatten.map { |r| resource_type_codes[r] }
      end

      def controlfield_value(controlfield, position, translation_map)
        controlfield.collect { |f| translation_map[f.value.slice(position)] }
      end

      # Just checks if it has a 502, if it does it"s considered a thesis
      def thesis?
        @thesis_q ||= begin
                        ! record.find { |a| a.tag == "502" }.nil?
                      end
      end

      # Just checks all $6xx for a $v "Congresses"
      def proceeding?
        controlfield_008 = record.find_all { |f| f.tag == "008" }
        @proceeding_q ||= begin
                            ! record.find do |field|
                              (field.tag.slice(0) == "6" &&
                                field.subfields.find { |sf| sf.code == "v" && /^\s*(C|c)ongresses\.?\s*$/.match(sf.value) }) ||
                              (controlfield_008.any? { |f| f.value[29] == "1" unless f.value[29].nil? })
                            end.nil?
                          end
      end

      def govdoc?
        controlfield_008 = record.find_all { |f| f.tag == "008" }
        ("aefgkmort".include? record.leader[06]) &&
          controlfield_008.any? { |f| "acfilmo".include? f.value[28] unless f.value[28].nil? }
      end

      # downcased version of the gmd, or else empty string
      def normalized_gmd
        @gmd ||= begin
                   ((a245 = record["245"]) && a245["h"] && a245["h"].downcase) || ""
                 end
      end
    end
  end
end
