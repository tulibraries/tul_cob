# frozen_string_literal: true

class JsonStore < ApplicationRecord
  serialize :value, JSON
end
