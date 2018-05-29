# frozen_string_literal: true

require "rails_helper"

RSpec.describe CatalogController, type: :controller, relevance: true do

  describe "Query results as JSON" do
    render_views

    context "to check that the search results" do
      fixtures = YAML.load_file("#{fixture_path}/search_features.yml")
      test_queries = fixtures.fetch("results_queries")
      docs = []
      # Take the test queries from the YAML file one at a time...
      test_queries.each do |test_item|
        search_string = ""
        # Concatenate the specified search terms into one search string
        test_item["query_type"].each do |query_field|
          search_term = test_item[query_field]
          if search_term.kind_of?(Array) == true
            search_term = search_term[0].to_s
          end
          search_string += search_term + " "
        end

        it "for search #{search_string} contains the correct items in the correct order" do
          # Perform the search and concatenate the first two pages of results (we aren't interested in results past 2 pages)
          for page in [1..2] do
            get(:index, params: { q: search_string, page: page.to_s }, format: "json")
            docs += JSON.parse(response.body)["response"]["docs"]
          end

          # For every item returned in the search...
          docs.each do |search_result|
            # The magic here is that we have to invert our way of looking at expected results vs actual results
            # We're going to see if each returned item exists in our set of expect results...
            # (And that we haven't run out of expected items to check)
            if test_item.include?("doc_id") && test_item["doc_id"].size > 0
              # ...And if the item is found in our list...
              if test_item["doc_id"].include?(search_result["id"])
                # ...Remove it from the list of expected items
                # The goal being to empty the list of expected items.
                # Once it's empty, we know all items have been found and the test is fulfilled.
                test_item["doc_id"].delete(search_result["id"])
              end
            # Once we've emptied the list of primary results, now we can look for secondary results in the same manner
            elsif test_item["doc_id"].size == 0 && test_item.include?("secondary_id") && !(test_item["secondary_id"].nil?) && test_item["secondary_id"].length > 0
              if test_item["secondary_id"].include?(search_result["id"])
                test_item["secondary_id"].delete(search_result["id"])
              end
            end
          end
          # If the test is about to fail, print some helpful debugging information
          if (test_item["doc_id"].length > 0) || (test_item.include?("secondary_id") && !(test_item["secondary_id"].nil?) && test_item["secondary_id"].length > 0)
            puts "\n search string:"
            puts search_string
            puts "\n test item (ids not found):"
            puts test_item
            puts "\n"
            puts "\n search results:"
            puts docs
            puts "\n"
          end
          # The test conditions are, we've found all our primary items and removed them from the test list,
          # And that we've found all the secondary items if there are any for this test
          expect(test_item).to satisfy { test_item["doc_id"].length == 0 }
          expect(test_item).to satisfy { test_item.exclude?("secondary_id") || (test_item["secondary_id"].nil?) || test_item["secondary_id"].length == 0 }
        end
      end
    end
  end
end
