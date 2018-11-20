#!/usr/bin/env ruby
# frozen_string_literal: true

require "alma/electronic"

module Alma
  # Holds some custom business logic for our Alma Electronic API.
  # This class is not intended for public use.
  class Electronic::Business
    # The Service ID is usually the Collection ID grouped by
    # 2 digits with the first number incremented by 1 and the
    # fifth number decremented by 1.
    #
    # @note However, this pattern does not hold for all cases.
    #
    # @param collection_id [String] The electronic collection id.
    def service_id(collection_id)
      collection_id.scan(/.{1,2}/).each_with_index.map { |char, index|
        if index == 0
          "%02d" % (char.to_i + 1)
        elsif index == 4
          "%02d" % (char.to_i - 1)
        else
          char
        end
      }.join
    end
  end
end
