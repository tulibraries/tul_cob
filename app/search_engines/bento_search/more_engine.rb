# frozen_string_literal: true

module BentoSearch
  class MoreEngine < BlacklightEngine
    def search_implementation(args)
      query = args.fetch(:query, "")
      per_page = args.fetch(:per_page)

      query = { q: query, per_page: per_page, seach_field: "advanced" }

      response = search_results(query, &proc_minus_books_journals).first

      item = BentoSearch::ResultItem.new(custom_data: response)

      (results(response.response))
        .append(item)
    end

    def proc_minus_books_journals
      Proc.new { |builder|
        processor_chain = [ :no_books_or_journals ]
        builder.append(*processor_chain)
      }
    end
  end
end
