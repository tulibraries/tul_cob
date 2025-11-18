# frozen_string_literal: true

require "rails_helper"

RSpec.describe BentoSearch::ArchivalCollectionsEngine do
  let(:engine) { described_class.new }

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
        "primary_type" => "archival_object",
        "uri" => "/repositories/4/archival_objects/123",
        "json" => raw_json,
        "dates" => [{ "expression" => "March 15, 2002" }]
      }
    end

    it "extracts the title from raw JSON" do
      result = engine.conform_to_bento_result(item)
      expect(result.title).to eq("Raw JSON Title")
    end

    it "extracts the collection ref" do
      result = engine.conform_to_bento_result(item)
      expect(result.custom_data["collection_ref"])
        .to eq("/repositories/4/resources/127")
    end

    it "extracts the collection title" do
      result = engine.conform_to_bento_result(item)
      expect(result.custom_data["collection_title"])
        .to eq("Asian Arts Initiative Records")
    end

    it "extracts the publication date" do
      result = engine.conform_to_bento_result(item)
      expect(result.publication_date).to eq("March 15, 2002")
    end

    it "sets the correct link" do
      result = engine.conform_to_bento_result(item)
      expect(result.link)
        .to eq("https://scrcarchivesspace.temple.edu/repositories/4/archival_objects/123")
    end

    it "sets primary type label" do
      result = engine.conform_to_bento_result(item)
      expect(result.custom_data["primary_type_labels"]).to eq("File")
    end
  end
end
