# frozen_string_literal: true

require "rails_helper"

RSpec.describe CatalogController, :focus, type: :controller, relevance: true do
  render_views

  let(:response) { JSON.parse(get(:index, params: { q: search_term, per_page: 100 }, format: "json").body) }

  describe "a search for" do


    context "epistemic injustice" do
      let(:search_term) { "epistemic injustice" }

      it "has expected results before a less relevant result" do
        expect(response)
          .to include_docs(%w[991024847639703811 991024847639703811 991033452769703811])
          .before(["991036813237303811"])
      end
    end

    context "Cabinet of Caligari" do
      let(:search_term) { "Cabinet of Caligari" }

      xit "has expected results before a less relevant result" do
        expect(response)
          .to include_docs(%w[991020778949703811 991001777289703811 991027229969703811 991001812089703811 991036804904003811])
          .before(["991029142769703811"])
      end
    end

    context "Clarice Lispector" do
      let(:search_term) { "Clarice Lispector" }

      it "returns items about the author before books by the author" do
        expect(response)
          .to include_docs(%w[991036730479303811 991033955589703811 991036853181403811])
          .within_the_first(10)
      end
    end

    context "Basquiat" do
      let(:search_term) { "Basquiat" }

      it "returns relevant documents about Basquiat" do
        expect(response)
          .to include_docs(%w[991032082719703811 991013618249703811 991004084189703811 991002158879703811 991009887669703811])
          .within_the_first(10)
      end
    end


    context "crypto-jews" do
      let(:search_term) { "crypto-jews" }
      it "with hyphen has results about crypto-Jews and crypto-judaism above results about cryptography" do
        expect(response)
          .to include_docs(
            %w[991036813411403811 991036730245703811 991036421349703811 991032963459703811
              991025064439703811 991033710779703811 991036732155603811])
          .before(%w[991036800002703811 991026974219703811 991013963759703811])
      end

      let(:search_term) { "crypto jews" }
      it "without hyphen has results about crypto-Jews and crypto-judaism above results about cryptography" do
        expect(response)
          .to include_docs(
            %w[991036813411403811 991036730245703811 991036421349703811 991032963459703811
              991025064439703811 991033710779703811 991036732155603811])
          .before(%w[991036800002703811 991026974219703811 991013963759703811])
      end
    end
  end
end
