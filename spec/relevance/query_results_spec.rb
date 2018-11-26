# frozen_string_literal: true

require "rails_helper"

RSpec.describe CatalogController, type: :controller, relevance: true do
  render_views

  let(:search_term) { search_terms.values.join(" ") }

  let(:per_page) { 20 }

  let(:query) { { q: search_term, per_page: per_page, format: "json" } }

  let(:response) { get(:index, params: query) }

  let(:results) { JSON.parse(response.body) }

  let(:ids) { (results.dig("response", "docs") || {}).map { |doc| doc.fetch("id") }.compact }

  describe "Query results as JSON" do
    context "search for title 'peer interaction and second language learning'" do
      let(:search_terms)  { { title: "peer interaction and second language learning" } }
      let(:primary_ids) { [
        "991001254809703811",
        "991022272009703811" ] }

      it "returns expected values" do
        expect(ids).to include_items(primary_ids)
      end
    end

    context "search for title 'hillbilly elegy'" do
      let(:search_terms) { { title: "hillbilly elegy" } }
      let(:primary_ids) { [ "991024587289703811" ] }

      it "returns expected values" do
        expect(ids).to include_items(primary_ids)
      end
    end

    context "search 'Temple university 125 years of service to philadelphia'" do
      let(:search_terms) {
        { title: "Temple university",
          subtitle: "125 years of service to philadelphia" } }

      let(:primary_ids) {
        [ "991036742233003811",
          "991017814679703811",
          "991001513649703811",
          "991002431869703811" ] }

      it "returns expected values" do
        expect(ids).to include_items(primary_ids)
      end
    end

    context "search 'our children's future child care policy in canada'" do
      let(:search_terms) {
        { title: "our children's future",
          subtitle: "child care policy in canada" } }

      let(:primary_ids) {
        [ "991036816752403811",
          "991024784309703811" ] }

      it "returns expected values" do
        expect(ids).to include_items(primary_ids)
      end
    end

    context "search 'new england journal of medicine'" do
      let(:search_terms) { { title: "new england journal of medicine" } }
      let(:primary_ids) {
        [ "991036753565903811",
          "991026206569703811" ] }

      it "returns expected values" do
        expect(ids).to include_items(primary_ids)
      end
    end

    context "search 'foot and ankle international'" do
      let(:search_terms) { { title: "foot and ankle international" } }
      let(:primary_ids) {
        [ "991036791313203811",
          "991011580459703811"] }

      it "returns expected values" do
        expect(ids).to include_items(primary_ids)
      end
    end

    context "search 'chronicle of higher education'" do
      let(:search_terms) { { title: "chronicle of higher education" } }
      let(:primary_ids) {
        [ "991036721510203811",
          "991012152319703811",
          "991017377949703811",
          "991006975379703811" ] }

      it "returns expected values" do
        expect(ids).to include_items(primary_ids)
      end
    end

    context "search 'housing association of delaware valley records'" do
      let(:search_terms) { { title: "housing association of delaware valley records" } }
      let(:primary_ids) { [ "991003108369703811" ] }

      it "returns expected values" do
        expect(ids).to include_items(primary_ids)
      end
    end

    context "search 'lawrence gitman'" do
      let(:search_terms) { { author: "lawrence gitman" } }
      let(:primary_ids) { [ "991008448689703811" ] }

      it "returns expected values" do
        expect(ids).to include_items(primary_ids)
      end
    end

    context "search 'miles livy'" do
      let(:search_terms) { { keywords: "miles livy" } }
      let(:primary_ids) { [ "991034319589703811" ] }

      it "returns expected values" do
        expect(ids).to include_items(primary_ids)
      end
    end

    context "search 'moter learning magill'" do
      let(:search_terms) { { keywords: "motor learning magill" } }
      let(:primary_ids) {
        [ "991009723459703811",
          "991022257719703811" ] }

      it "returns expected values" do
        expect(ids).to include_items(primary_ids)
      end
    end

    context "search 'Mahlon Howard Hellerich dissertation'" do
      let(:search_terms) { { keywords: "Mahlon Howard Hellerich dissertation" } }
      let(:primary_ids) { [ "991034105309703811" ] }
      it "returns expected values" do
        expect(ids).to include_items(primary_ids)
      end
    end

    context "search '00095982'" do
      let(:search_terms) { { ISSN: "00095982" } }
      let(:primary_ids) {
        [ "991036721510203811",
          "991012152319703811",
          "991017377949703811",
          "991006975379703811" ] }

      it "returns expected values" do
        expect(ids).to include_items(primary_ids)
      end
    end

    context "search '9780140449198'" do
      let(:search_terms) { { ISBN: "9780140449198" } }
      let(:primary_ids) { [ "991006700799703811" ] }

      it "returns expected values" do
        expect(ids).to include_items(primary_ids)
      end
    end

    context "search '0140449191'" do
      let(:search_terms) { { ISBN: "0140449191" } }
      let(:primary_ids) { [ "991006700799703811" ] }

      it "returns expected values" do
        expect(ids).to include_items(primary_ids)
      end
    end

    context "search '991036743832103811'" do
      let(:search_terms) { { doc_id: "991036743832103811" } }
      let(:primary_ids) { [ "991036743832103811" ] }

      it "returns expected values" do
        expect(ids).to include_items(primary_ids)
      end
    end

    context "search '991035120939703811'" do
      let(:search_terms) { {  callnum: '"PN1997.2 .S462x 2003"' } }
      let(:primary_ids) { [ "991035120939703811" ] }
      it "returns expected values" do
        expect(ids).to include_items(primary_ids)
      end
    end

    context "search 'bicycle thieves'" do
      let(:search_terms) { { title: "bicycle thieves" } }
      let(:primary_ids) {
        [ "991024736809703811",
          "991035018259703811" ] }

      it "returns expected values" do
        expect(ids).to include_items(primary_ids)
      end
    end

    context "search 'journal of materials chemistry'" do
      let(:search_terms) { { title: "journal of materials chemistry" } }
      let(:primary_ids) { [ "991036749632703811" ] }
      let(:secondary_ids) {
        [ "991036749633503811",
          "991036749630403811",
          "991036749630103811" ] }

      it "returns expected values" do
        expect(ids).to include_items(primary_ids)
          .before(secondary_ids)
      end
    end

    context "search 'new york times'" do
      let(:search_terms) { { title: "new york times" } }
      let(:primary_ids) {
        [ "991036797063703811",
          "991026245969703811" ] }

      it "returns expected values" do
        expect(ids).to include_items(primary_ids)
      end
    end

    context "search 'gray's anatomy the anatomical basis of clinical practice'" do
      let(:search_terms) {
        { title: "gray's anatomy",
          subtitle: "the anatomical basis of clinical practice" } }
      let(:primary_ids) {
        [ "991007333849703811",
          "991003194609703811",
          "991028264669703811" ] }

      it "returns expected values" do
        expect(ids).to include_items(primary_ids)
      end
    end

    context "search 'Handbook on injectable drugs'" do
      let(:search_terms) { { title: "Handbook on injectable drugs" } }
      let(:primary_ids) { [ "991000868839703811" ] }
      let(:secondary_ids) {
        [ "991033401389703811",
          "991011446329703811",
          "991036802592903811" ] }

      it "returns expected values" do
        expect(ids).to include_items(primary_ids)
          .before(secondary_ids)
      end
    end

    context "search 'the epic of gilgamesh'" do
      let(:search_terms) { { title: "the epic of gilgamesh" } }
      let(:primary_ids) {
        [ "991006700799703811",
          "991017636819703811",
          "991006996069703811",
          "991013242359703811",
          "991029586949703811" ] }
      let(:secondary_ids) {
        [ "991036749005103811",
          "991036742769003811" ] }

      it "returns expected values" do
        expect(ids).to include_items(primary_ids)
          .before(secondary_ids)
      end
    end
  end
end

RSpec.describe "include_items().within_index().before()" do
  it "works with positive assertions" do
    expect(["a", "b", "c", "d", "e"]).to include_items(["c", "b"])
      .before(["e", "d"])
  end

  it "works with negative assertions" do
    expect(["c", "b", "a", "d", "e"]).not_to include_items(["f", "d"])
      .before(["c", "b"])
  end
end
