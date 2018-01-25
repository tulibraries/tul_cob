require "rails_helper"

RSpec.describe CatalogController, type: :controller do

  describe "Query results as JSON" do
    render_views

    context 'to check that the search results' do
      fixtures = YAML.load_file("#{fixture_path}/search_features.yml")
      test_queries = fixtures.fetch("results_queries")
      docs = []
      test_queries.each do |test_item|
        search_string = ""

        test_item['query_type'].each do |query_field|
          search_term = test_item[query_field]
          if search_term.kind_of?(Array) == true
            search_term = search_term.to_s
          end
          search_string += search_term + " "
        end

        it "for search #{search_string}" do
          for page in [1..2] do
            get(:index, params: {q: search_string, page: page.to_s}, :format => :json)
            docs += JSON.parse(response.body)["response"]["docs"]
          end

          docs.each do |search_result|
            if test_item.include?("doc_id") && test_item["doc_id"].size > 0
              if test_item["doc_id"].include?(search_result["id"])
                test_item["doc_id"].delete(search_result["id"])
              end
            elsif test_item.include?("secondary_id") && !(test_item["secondary_id"].nil?) && test_item["secondary_id"].length > 0
              if test_item["secondary_id"].include?(search_result["id"])
                test_item["secondary_id"].delete(search_result["id"])
              end
            end
          end
          if (test_item["doc_id"].length > 0) || (test_item.include?("secondary_id") && !(test_item["secondary_id"].nil?) && test_item["secondary_id"].length > 0)
            puts 'test_item["doc_id"].length > 0'
            puts "\n search string:"
            puts search_string
            puts "\n test item (ids not found):"
            puts test_item
            puts "\n"
            puts "\n search results:"
            puts docs
            puts "\n"
          end
          #binding.pry
          expect(test_item).to satisfy { test_item["doc_id"].length == 0 }
          expect(test_item).to satisfy { test_item.exclude?("secondary_id") || (test_item["secondary_id"].nil?) || test_item["secondary_id"].length == 0 }
        end
      end
    end
  end
end
