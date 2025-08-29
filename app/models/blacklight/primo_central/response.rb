# frozen_string_literal: true

module Blacklight::PrimoCentral
  class Response < HashWithIndifferentAccess
    include Blacklight::PrimoCentral::Facets
    include Kaminari::PageScopeMethods
    include Kaminari::ConfigurationMethods::ClassMethods
    include Blacklight::PrimoCentral::SolrAdaptor
    include BlacklightRangeLimit::SegmentCalculation

    attr_reader :request_params, :total
    attr_accessor :document_model, :blacklight_config

    def initialize(data, request_params = {}, options = {})
      @docs = begin data["docs"] rescue [ data ] end || [ data ]
      @request_params = request_params.with_indifferent_access

      self.document_model = ::PrimoCentralDocument
      self.blacklight_config = options[:blacklight_config]

      # Add stats for range facets
      facets = data["facets"] || []
      stats = options[:stats] || get_range_stats(facets, request_params[:range])
      @total = options[:numFound] || 1

      super(response: { numFound: @total, start: self.start, docs: documents }, facets:, stats:)
    end

    # Generates stats for range fields in a solr format.
    def get_range_stats(facets, range = OpenStruct.new)
      range_facet_fields = (blacklight_config&.facet_fields || {})
        .select { |name, field| field[:range] }.keys

      stats = facets.select { |f| range_facet_fields.include? f["name"] }
        .map { |field|

        values = field["values"]
          .map { |f| { value: f["value"].to_i, count: f["count"] } }
          .sort_by { |f| f[:value] }

        min = (range&.min || values&.first&.fetch(:value, 0)).to_i
        max = (range&.max || values&.last&.fetch(:value, 9999)).to_i
        raise BlacklightRangeLimit::InvalidRange, "The min date must be before the max date" if min > max

        data = facet_segments(field["name"], min, max, values)
        stat = { min:, max:, missing: 0, data: }
        [field["name"], stat]
      }.to_h

      { stats_fields: stats }
    end

    def facet_segments(field, min, max, values)
      segments = []
      field_config = blacklight_config.facet_fields[field.to_s]
      boundaries = boundaries_for_range_facets(min, max, (field_config[:num_segments] || 10))

      # Now make the boundaries into actual filter.queries.
      0.upto(boundaries.length - 2) do |index|
        first = boundaries[index]
        last =  boundaries[index + 1].to_i - 1
        count = values.select { |f| f[:value] >= first && f[:value] <= last }
          .map { |f| f[:count].to_i }
          .reduce(0, &:+)

        segments << { from: first, to: last, count: }
      end
      segments
    end

    def documents
      @documents ||= (@docs || []).collect { |doc|
        options = { blacklight_config: }
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
      $stderr.puts("Call to Response##{meth} from Blacklight::PrimoCentral::Response")
      super if respond_to? :super
    end
  end
end
