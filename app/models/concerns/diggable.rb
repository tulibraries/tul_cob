# frozen_string_literal: true

# Add hash like properties to our documents lost in BL-7.
module Diggable
  extend ActiveSupport::Concern

  included do
    delegate :dig, :[], to: :@_source
  end


  def []=(key, value)
    @_source = @_source.merge("#{key}": value)
  end
end
