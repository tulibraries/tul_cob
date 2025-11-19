# frozen_string_literal: true

require "rails_helper"

RSpec.describe ArchivalDecorator do
  let(:view_context) { ApplicationController.renderer }

  let(:result_item) do
    BentoSearch::ResultItem.new(
      title: "Test",
      custom_data: custom_data
    )
  end

  let(:decorator) { ArchivalDecorator.new(result_item, view_context) }

  describe "#display_date" do
    context "when archival_dates is present" do
      let(:custom_data) { { "archival_dates" => "March 15, 2002" } }

      it "returns labeled date HTML" do
        expect(decorator.display_date)
          .to eq("<span class='bento-label'>Dates: </span>March 15, 2002")
      end
    end

    context "when archival_dates is missing" do
      let(:custom_data) { {} }

      it "falls back to super" do
        expect(decorator.display_date).to be_nil.or be_a(String)
      end
    end
  end

  describe "#collections" do
    context "when collection data is present" do
      let(:custom_data) do
        {
          "collection_ref" => "/repositories/4/resources/127",
          "collection_title" => "Asian Arts Initiative Records"
        }
      end

      it "returns linked collection HTML" do
        expect(decorator.collections)
          .to eq(
            "<span class='bento-label'>In collection: </span>" \
            "<a href='https://scrcarchivesspace.temple.edu/repositories/4/resources/127'>" \
            "Asian Arts Initiative Records</a>"
          )
      end
    end

    context "when collection_ref is missing" do
      let(:custom_data) { {} }

      it "returns nil" do
        expect(decorator.collections).to be_nil
      end
    end
  end

  describe "#primary_types" do
    context "when primary data is present" do
      let(:custom_data) do
        {
          "primary_types" => "archival_object",
          "primary_type_labels" => "File"
        }
      end

      it "returns icon and label" do
        expect(decorator.primary_types)
          .to eq("<span class='archival_object'></span> File")
      end
    end

    context "when primary_types is missing" do
      let(:custom_data) { {} }

      it "falls back to super" do
        expect(decorator.primary_types).to be_nil.or be_a(String)
      end
    end
  end

  describe "#primary_type_icon" do
    let(:custom_data) { {} }

    it "returns correct icon for archival_object" do
      expect(decorator.primary_type_icon("archival_object"))
        .to eq("<span class='archival_object'></span>")
    end

    it "returns correct icon for resource" do
      expect(decorator.primary_type_icon("resource"))
        .to eq("<span class='resource'></span>")
    end

    it "returns empty HTML for unknown type" do
      expect(decorator.primary_type_icon("unknown"))
        .to eq("")
    end
  end
end
