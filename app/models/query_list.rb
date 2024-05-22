# frozen_string_literal: true


class QueryList
  include ActiveModel::Model

  attr_accessor :documents

  validates :documents, presence: true
end
