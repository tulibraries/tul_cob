# frozen_string_literal: true

require "rails_helper"

RSpec.describe SolrDocument, type: :model do
  let(:document) { SolrDocument.new(id: "991012041239703811", marc_display_raw: "foobar") }

  it "handles Email" do
    expect(document).to respond_to(:to_email_text)
  end
  it "handles SMS" do
    expect(document).to respond_to(:to_sms_text)
  end

  it "handles to Marc messages" do
    expect(document).to respond_to(:to_marc)
  end

  let(:item_one) { Alma::BibItem.new(
    "bib_data" => { "title" => "Hello World" },
    "item_data" => {
      "physical_material_type" => { "value" => "BOOK" },
      "barcode" => "FOOBAR",
    },
    "holding_data" => { "calling_number" => "CALL ME" }
  ) }

  let(:item_two) { Alma::BibItem.new(
    "item_data" => { "physical_material_type" => { "value" => "NOT BOOK" } }
  ) }

  let(:bib_items) { [ item_one, item_two ] }

  before(:each) {
    allow(document).to receive(:materials_data) { Proc.new { bib_items } }
  }

  describe "#books" do
    context "No items found" do
      let(:bib_items) { [] }

      it "returns an empty set of books" do
        expect(document.books).to be_empty
      end
    end

    context "No book items found" do
      let(:bib_items) { [ item_two ] }

      it "returns an empty set of books" do
        expect(document.books).to be_empty
      end
    end

    context "A book item is found" do
      let(:bib_items) { [ item_one, item_two ] }

      it "returns a set of books" do
        expect(document.books.count).to eq(1)
      end
    end
  end

  describe "#books_from_barcode" do
    context "no barcode is given" do
      it "does not return a book" do
        expect(document.book_from_barcode).to be_nil
      end
    end

    context "an incorrect barcode is given" do
      it "does not return a book" do
        expect(document.book_from_barcode("FOO")).to be_nil
      end
    end

    context "a correct barcode is given" do
      it "return a book" do
        expect(document.book_from_barcode("FOOBAR")[:title]).to eq("Hello World")
      end
    end
  end

  describe "#barcodes" do
    context "no items found"  do
      let(:bib_items) { [] }

      it "returns and empty set" do
        expect(document.barcodes).to be_empty
      end
    end

    context "non book item found" do
      let(:bib_items) { [ item_two ] }

      it "returns and empty set" do
        expect(document.barcodes).to be_empty
      end
    end

    context "a book item was found" do
      let(:bib_items) { [ item_one, item_two ] }

      it "returns a set of barcodes" do
        expect(document.barcodes).to eq(["FOOBAR"])
      end
    end
  end

  describe "#valid_barcode?" do
    context "no barcode supplied" do
      it "invalidates nil barcodes" do
        expect(document.valid_barcode?).to be(false)
      end
    end

    context "an invalid barcode is supplied" do
      it "invalidates the barcode" do
        expect(document.valid_barcode? "FOO").to be(false)
      end
    end

    context "a valid barcode is supplied" do
      it "validates the barcode" do
        expect(document.valid_barcode? "FOOBAR").to be(true)
      end
    end
  end

  # It's currently private but I'm testing anyway because it's complicated logic.
  describe "#availability_status" do
    context "book in place and not circulating" do
      it "sets availability to library use only" do
        allow(item_one).to receive(:in_place?) { true }
        allow(item_one).to receive(:non_circulating?) { true }

        expect(document.book_from_barcode("FOOBAR")[:availability]).to eq("Library Use Only")
      end
    end

    context "book in place and circulating" do
      it "sets availability to available" do
        allow(item_one).to receive(:in_place?) { true }

        expect(document.book_from_barcode("FOOBAR")[:availability]).to eq("Available")
      end
    end

    context "book is missing" do
      it "sets availability to missing" do
        allow(item_one).to receive(:has_process_type?) { true }
        allow(item_one).to receive(:process_type) { "MISSING" }

        expect(document.book_from_barcode("FOOBAR")[:availability]).to eq("Missing")
      end
    end

    context "unknown" do
      it "sets availability to checked out or currently unavailable" do
        expect(document.book_from_barcode("FOOBAR")[:availability]).to eq("Checked out or currently unavailable")
      end
    end
  end
end
