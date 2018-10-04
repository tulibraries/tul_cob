# frozen_string_literal: true

module Blacklight::Alma
  # This class added mostly to provide pagination for alma bib items.
  class Response < HashWithIndifferentAccess
    include Kaminari::PageScopeMethods
    include Kaminari::ConfigurationMethods::ClassMethods

    attr_reader :request_params, :total
    attr_accessor :document_model, :blacklight_config

    def initialize(bib_items, request_params = nil, options = {})
      @request_params = request_params
      @items = bib_items.to_a
      @total = bib_items.total_record_count

      super(response: { total_count: @total, start: self.start })
    end

    def limit_value
      100
    end

    def total_count
      total
    end

    def offset_value
      start
    end

    def params
      @request_params || { offset: 0, limit: limit_value }
        .with_indifferent_access
    end

    def start
      page = (params[:page] || 1).to_i
      limit = (params[:limit] || limit_value).to_i
      (limit * page) - limit
    end

    def rows
      @items.count
    end

    def method_missing(meth, *args)
      $stderr.puts("Call to Response##{meth}")
      super if respond_to? :super
    end
  end
end
