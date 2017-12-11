module Blacklight::PrimoCentral
  class Response < HashWithIndifferentAccess

    #include Blacklight::PrimoCentral::Response::Response
    include Kaminari::PageScopeMethods
    include Kaminari::ConfigurationMethods::ClassMethods

    attr_reader :request_params, :total
    attr_accessor :document_model, :blacklight_config

    def initialize(data, request_params, options = {})
      @docs = data.docs
      @request_params = request_params.with_indifferent_access
      self.document_model =  ::PrimoCentralDocument
      self.blacklight_config = options[:blacklight_config]

      facet_counts = options.fetch(:facet_counts, {})
      @total = options[:numFound]
      super(response: {numFound: @total, start: self.start, docs: documents},
            facet_counts: facet_counts
      )
    end

    def documents
      @documents ||= (@docs || []).collect{|doc| document_model.new(doc, self) }
    end

    def limit_value
      10
    end

    def aggregations
      {}
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
      params[:start].to_i
    end

    def rows
      params[:rows].to_i
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
