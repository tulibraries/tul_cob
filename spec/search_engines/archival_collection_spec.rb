# frozen_string_literal: true

require "rails_helper"

RSpec.describe BentoSearch::ArchivalCollectionsEngine do
  subject(:engine) { described_class.new }

  describe "#search_implementation" do
    let(:service) { instance_double(ArchivesSpaceService) }
    let(:records) { [{ "uri" => "/repositories/4/resources/127" }] }

    before do
      allow(ArchivesSpaceService).to receive(:new).and_return(service)
    end

    it "searches ArchivesSpace with the query and allowed types" do
      expect(service).to receive(:search)
        .with("music", types: engine.allowed_types)
        .and_return(records)
      expect(engine).to receive(:results).with(records).and_return(:results)

      expect(engine.search_implementation(query: "music")).to eq(:results)
    end

    it "uses an empty query when one is not provided" do
      expect(service).to receive(:search)
        .with("", types: engine.allowed_types)
        .and_return(records)
      expect(engine).to receive(:results).with(records).and_return(:results)

      expect(engine.search_implementation({})).to eq(:results)
    end
  end

  describe "#results" do
    let(:records) { [{ "id" => "one" }, { "id" => "two" }] }
    let(:first_result) { instance_double(BentoSearch::ResultItem) }
    let(:second_result) { instance_double(BentoSearch::ResultItem) }

    it "sets the total and conforms each record" do
      expect(engine).to receive(:conform_to_bento_result).with(records[0]).and_return(first_result)
      expect(engine).to receive(:conform_to_bento_result).with(records[1]).and_return(second_result)

      results = engine.results(records)

      expect(results).to eq([first_result, second_result])
      expect(results.total_items).to eq(query_total: 2)
    end

    it "returns an empty result set for no records" do
      results = engine.results([])

      expect(results).to be_empty
      expect(results.total_items).to eq(query_total: 0)
    end
  end

  describe "#allowed_types" do
    it "returns the expected type list" do
      expect(engine.allowed_types).to eq(
        %w[
          agent_corporate_entity
          agent_family
          agent_person
          archival_object
          classification
          resource
        ]
      )
    end
  end

  describe "#aspace_item_url" do
    it "builds the correct URL" do
      item = { "uri" => "/repositories/4/resources/127" }

      expect(engine.aspace_item_url(item))
        .to eq("https://scrcarchivesspace.temple.edu/repositories/4/resources/127")
    end

    it "uses the public base URL when the item has no URI" do
      expect(engine.aspace_item_url({}))
        .to eq("https://scrcarchivesspace.temple.edu")
    end
  end

  describe "#conform_to_bento_result" do
    let(:raw_json) do
      {
        "title" => "Raw JSON Title",
        "instances" => [
          {
            "sub_container" => {
              "top_container" => {
                "_resolved" => {
                  "collection" => [
                    {
                      "ref" => "/repositories/4/resources/127",
                      "display_string" => "Asian Arts Initiative Records"
                    }
                  ]
                }
              }
            }
          }
        ]
      }.to_json
    end

    let(:item) do
      {
        "primary_type" => "archival_object.",
        "level" => "series.",
        "uri" => "/repositories/4/archival_objects/123",
        "json" => raw_json,
        "dates" => [{ "expression" => "March 15, 2002" }]
      }
    end

    it "extracts the title from raw JSON" do
      expect(engine.conform_to_bento_result(item).title).to eq("Raw JSON Title")
    end

    it "extracts the collection ref and title" do
      result = engine.conform_to_bento_result(item)

      expect(result.custom_data["collection_ref"])
        .to eq("/repositories/4/resources/127")
      expect(result.custom_data["collection_title"])
        .to eq("Asian Arts Initiative Records")
    end

    it "extracts the publication date" do
      expect(engine.conform_to_bento_result(item).publication_date)
        .to eq("March 15, 2002")
    end

    it "sets the link and publisher" do
      result = engine.conform_to_bento_result(item)

      expect(result.link)
        .to eq("https://scrcarchivesspace.temple.edu/repositories/4/archival_objects/123")
      expect(result.publisher).to eq(" ")
    end

    it "sets normalized archival metadata" do
      custom_data = engine.conform_to_bento_result(item).custom_data

      expect(custom_data["archival_dates"]).to eq("March 15, 2002")
      expect(custom_data["raw"]).to eq(raw_json)
      expect(custom_data["primary_types"]).to eq("archival_object")
      expect(custom_data["primary_type_labels"]).to eq("File")
      expect(custom_data["level"]).to eq("series")
    end

    BentoSearch::ArchivalCollectionsEngine::PRIMARY_TYPE_LABELS.each do |primary_type, label|
      it "maps #{primary_type} to #{label}" do
        result = engine.conform_to_bento_result(item.merge("primary_type" => "#{primary_type}."))

        expect(result.custom_data["primary_type_labels"]).to eq(label)
      end
    end

    it "sets collection metadata to nil when no collection is resolved" do
      raw_without_collection = { "title" => "Unassociated Record" }.to_json
      result = engine.conform_to_bento_result(item.merge("json" => raw_without_collection))

      expect(result.custom_data["collection_ref"]).to be_nil
      expect(result.custom_data["collection_title"]).to be_nil
    end

    it "uses an empty label for an unknown primary type" do
      result = engine.conform_to_bento_result(item.merge("primary_type" => "unknown."))

      expect(result.custom_data["primary_type_labels"]).to eq("")
      expect(result.custom_data["primary_types"]).to eq("unknown")
    end

    it "uses the first string when the first date is not a hash" do
      result = engine.conform_to_bento_result(item.merge("dates" => ["1900-1950"]))

      expect(result.publication_date).to eq("1900-1950")
    end

    it "uses the expression when dates is a hash" do
      result = engine.conform_to_bento_result(item.merge("dates" => { "expression" => "1901" }))

      expect(result.publication_date).to eq("1901")
    end

    it "uses the date when dates is a string" do
      result = engine.conform_to_bento_result(item.merge("dates" => "1902"))

      expect(result.publication_date).to eq("1902")
    end

    it "uses nil when dates has an unsupported type" do
      result = engine.conform_to_bento_result(item.merge("dates" => 1903))

      expect(result.publication_date).to be_nil
    end
  end

  describe "#url" do
    it "builds an escaped ArchivesSpace search URL" do
      helper = double("ViewHelper", params: { q: "blue sky & archives" })

      expect(engine.url(helper)).to eq(
        "https://scrcarchivesspace.temple.edu/search?utf8=%E2%9C%93&op%5B%5D=&q%5B%5D=blue+sky+%26+archives&limit=&field%5B%5D=&from_year%5B%5D=&to_year%5B%5D=&commit=Search"
      )
    end
  end

  describe "#view_link" do
    it "renders a link to all archival collection results in a new tab" do
      helper = double("ViewHelper")
      expected_url = "https://scrcarchivesspace.temple.edu/search?q=music"

      expect(engine).to receive(:url).with(helper).and_return(expected_url)
      expect(helper).to receive(:link_to)
        .with("See all results", expected_url,
          class: "bento-full-results bento_archival_collections_header",
          target: "_blank")
        .and_return("<a>See all results</a>")

      expect(engine.view_link(12, helper)).to eq("<a>See all results</a>")
    end
  end

  describe "#archives_space_public_base_url" do
    it "returns the configured base URL without a trailing slash" do
      expect(engine.archives_space_public_base_url)
        .to eq("https://scrcarchivesspace.temple.edu")
    end
  end
end
