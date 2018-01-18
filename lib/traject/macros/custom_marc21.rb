require 'traject/marc_extractor'
require 'traject/translation_map'
require 'traject/util'
require 'base64'
require 'json'
require 'marc/fastxmlwriter'

module Traject::Macros
  # Some of these may be generic for any MARC, but we haven't done
  # the analytical work to think it through, some of this is
  # def specific to Marc21.
  module Marc21
    def self.trim_punctuation(str)

      # If something went wrong and we got a nil, just return it
      return str unless str

      # trailing: comma, slash, semicolon, colon (possibly preceded and followed by whitespace)
      str = str.sub(/ *[ ,\/;:] *\Z/, '')

      # trailing period if it is preceded by at least three letters (possibly preceded and followed by whitespace)
      str = str.sub(/( *[[:word:]]{3,})\. *\Z/, '\1')

      # single square bracket characters if they are the start and/or end
      #   chars and there are no internal square brackets.
      str = str.sub(/\A\[?([^\[\]]+)\]?\Z/, '\1')

      # removes period when preceded by a paentheses
      str = str.sub(/(?<=\))\./ , "")

      # trim any leading or trailing whitespace
      str.strip!

      return str
    end
  end
end
