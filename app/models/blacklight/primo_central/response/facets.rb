
# frozen_string_literal: true

module Blacklight
  module PrimoCentral
    class Response
      ##
      # Facets for {Europeana::Blacklight::Response}
      #
      # Based on {Blacklight::SolrResponse::Facets} v5.10.2
      module Facets
        require "ostruct"

        # represents a facet value; which is a field value and its hit count
        class FacetItem < OpenStruct
          def initialize(*args)
            options = args.extract_options!

            # Backwards-compat method signature
            value = args.shift
            hits = args.shift

            options[:value] = value if value
            options[:hits] = hits if hits

            super(options)
          end

          def label
            super || value
          end

          def as_json(props = nil)
            table.as_json(props)
          end
        end

        # represents a facet; which is a field and its values
        class FacetField
          attr_reader :name, :items

          def initialize(name, items, options = {})
            @name, @items = name, items
            @options = options
          end

          def limit
            @options[:limit] || default_limit
          end

          def offset
            @options[:offset] || default_offset
          end

          # Expected by {Blacklight::Facet#facet_paginator}
          def prefix
          end

          def sort
            # Europeana API does not support facet sorting
            nil
          end

          private

            # @see http://labs.europeana.eu/api/search/#offset-and-limit-of-facets
            def default_limit
              100
            end

            # @see http://labs.europeana.eu/api/search/#offset-and-limit-of-facets
            def default_offset
              0
            end
        end

        def aggregations
          @aggregations ||= {}.merge(facet_field_aggregations).merge(facet_query_aggregations)
        end

        def facet_fields
          @facet_fields ||= self["facets"] || []
        end

        def facet_queries
          @facet_queries ||= self["facet_queries"] || {}
        end

        private

          ##
          # Convert API's facets response into a hash of
          # {Blacklight::PrimoCentral::Response::Facet::FacetField} objects
          def facet_field_aggregations
            facet_fields.each_with_object({}) do |facet, hash|
              facet_field_name = facet["name"]
              items = sort_by_count_desc_alpha_asc(facet).collect do |value|
                FacetItem.new(value: value["value"], hits: value["count"])
              end

              if blacklight_config && blacklight_config.facet_fields[facet_field_name]
                if blacklight_config.facet_fields[facet_field_name].group.present?
                  items = grouped_facet_field_items(facet_field_name, items)
                end
              end

              hash[facet_field_name] = FacetField.new(facet_field_name, items, facet_field_aggregation_options(facet_field_name))

              if blacklight_config && !blacklight_config.facet_fields[facet_field_name]
                # alias all the possible blacklight config names..
                blacklight_config.facet_fields.select { |_k, v| v.field == facet_field_name }.each do |key, _|
                  hash[key] = hash[facet_field_name]
                end
              end
            end
          end

          def grouped_facet_field_items(facet_field_name, items)
            groups = {}

            items.each do |item|
              item_group = blacklight_config.facet_fields[facet_field_name].group.call(item)
              if groups.key?(item_group)
                groups[item_group].hits += item.hits
              else
                groups[item_group] = FacetItem.new(item_group, item.hits)
              end
            end

            groups.values.sort_by { |item| -item.hits }
          end

          def facet_field_aggregation_options(name)
            options = {}

            if params[:"f.#{name}.facet.limit"]
              options[:limit] = params[:"f.#{name}.facet.limit"].to_i
            elsif params[:'facet.limit']
              options[:limit] = params[:'facet.limit'].to_i
            end

            if params[:"f.#{name}.facet.offset"]
              options[:offset] = params[:"f.#{name}.facet.offset"].to_i
            elsif params[:'facet.offset']
              options[:offset] = params[:'facet.offset'].to_i
            end

            options
          end

          ##
          # Aggregate API's facet_query response into the virtual facet fields
          # defined in the blacklight configuration
          def facet_query_aggregations
            return {} unless blacklight_config

            query_facet_fields = blacklight_config.facet_fields.select { |_k, v| v.query }
            query_facet_fields.each_with_object({}) do |(field_name, facet_field), hash|
              facet_query_params = facet_field.query.map { |_k, v| v[:fq] }
              response_facet_queries = facet_queries.dup
              response_facet_queries.select! { |k, _hits| facet_query_params.include?(k) }
              response_facet_queries.reject! { |_k, hits| hits == 0 }

              items = response_facet_queries.map do |value, hits|
                salient_fields = facet_field.query.select { |_k, v| v[:fq] == value }
                key = ((salient_fields.keys if salient_fields.respond_to? :keys) || salient_fields.first).first
                FacetItem.new(value: key, hits: hits, label: facet_field.query[key][:label])
              end

              hash[field_name] = FacetField.new(field_name, items)
            end
          end

          def sort_by_count_desc_alpha_asc(facet)
            # Return facet values sorted first by Count Descending
            # Secondary sort by value Ascending, essentially alphabetical order
            facet["values"].sort_by { |h| [-h["count"], h["value"]] }
          end
      end
    end
  end
end
