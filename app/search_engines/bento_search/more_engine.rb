# frozen_string_literal: true

module BentoSearch
  class MoreEngine < BlacklightEngine
    def search_implementation(args)
      response = search_results(args.merge(per_page: 2), &proc_minus_books_journals).first

      item = BentoSearch::ResultItem.new(custom_data: response)

      results(response).append(item)
    end

    def proc_minus_books_journals
      Proc.new { |builder|
        processor_chain = [ :no_books_or_journals ]
        builder.append(*processor_chain)
      }
    end
  end
end
