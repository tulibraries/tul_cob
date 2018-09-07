# frozen_string_literal: true

module Blacklight::PrimoCentral
  class Response < HashWithIndifferentAccess
    include Blacklight::PrimoCentral::Response::Facets
    include Kaminari::PageScopeMethods
    include Kaminari::ConfigurationMethods::ClassMethods
    include Blacklight::PrimoCentral::SolrAdaptor

    attr_reader :request_params, :total
    attr_accessor :document_model, :blacklight_config

    def initialize(data, request_params, options = {})
      @docs = begin data["docs"] rescue [ data ] end || [ data ]
      @request_params = request_params.with_indifferent_access

      self.document_model = ::PrimoCentralDocument
      self.blacklight_config = options[:blacklight_config]

      #facets = begin data.facets rescue [] end
      facets = data["facets"] || []
      facet_counts = options.fetch(:facet_counts, {})

      @total = options[:numFound] || 1
      super(response: { numFound: @total, start: self.start, docs: documents },
            facet_counts: facet_counts, facets: facets
      )
    end

    def documents
      @documents ||= (@docs || []).collect { |doc|
        options = { blacklight_config: blacklight_config }
        document_model.new(doc.to_h.with_indifferent_access, options)
      }
    end

    def limit_value
      10
    end

    def total_count
      total
    end

    def offset_value
      start
    end

    def params
      request_params
    end

    def start
      params[:offset].to_i
    end

    def rows
      @docs.count
    end

    def sort
      params[:sort]
    end

    def grouped?
      false
    end

    def method_missing(meth, *args)
      $stderr.puts("Call to Response##{meth}")
      super if respond_to? :super
    end
  end
end
