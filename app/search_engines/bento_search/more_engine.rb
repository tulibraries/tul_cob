# frozen_string_literal: true

module BentoSearch
  class MoreEngine < BlacklightEngine
    def search_implementation(args)
      query = args.fetch(:query, "")
      query = { q: query }

      response = search_results(query, &proc_format_facet_only).first

      formats = filtered_format_facets(response)
      response.facet_counts["facet_fields"]["format"] = formats

      item = BentoSearch::ResultItem.new(custom_data: response)

      BentoSearch::Results.new << item
    end

    def filtered_format_facets(response)
      if response.facet_fields["format"]
        response.facet_counts["facet_fields"]["format"]
          .each_slice(2).to_h
          .select { |k, v| k != "Book" && k != "Journal/Periodical" }
          .to_a.flatten
      else
        []
      end
    end

    # Overrides the search builder process chain with [:format_facet_only].
    def proc_format_facet_only
      Proc.new { |builder|
        processor_chain = [ :add_query_to_solr, :format_facet_only ]
        builder.except(*builder.default_processor_chain)
          .append(*processor_chain)
      }
    end
  end
end
