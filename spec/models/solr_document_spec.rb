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
      "physical_material_type" => { "value" => "ANY" },
      "pid" => "FOOBAR",
    },
    "holding_data" => { "calling_number" => "CALL ME" }
  ) }

  let(:bib_items) { [ item_one ] }

  before(:each) {
    allow(document).to receive(:materials_data) { Proc.new { bib_items } }
  }

  describe "#materials" do
    context "No items found" do
      let(:bib_items) { [] }

      it "returns an empty set of materials" do
        expect(document.materials).to be_empty
      end
    end

    context "A material item is found" do
      let(:bib_items) { [ item_one ] }

      it "returns a set of materials" do
        expect(document.materials.count).to eq(1)
      end
    end

    context "Multiple equivalent items are found" do
      let(:bib_items) { [ item_one, item_one, item_one ] }

      it "returns a uniq set" do
        expect(document.materials.count).to eq(1)
      end
    end
  end

  describe "#materials_from_barcode" do
    context "no barcode is given" do
      it "does not return a material" do
        expect(document.material_from_barcode).to be_nil
      end
    end

    context "an incorrect barcode is given" do
      it "does not return a material" do
        expect(document.material_from_barcode("FOO")).to be_nil
      end
    end

    context "a correct barcode is given" do
      it "return a material" do
        expect(document.material_from_barcode("FOOBAR")[:title]).to eq("Hello World")
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

    context "non material item found" do
      let(:bib_items) { [] }

      it "returns and empty set" do
        expect(document.barcodes).to be_empty
      end
    end

    context "a material item was found" do
      let(:bib_items) { [ item_one ] }

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
    context "material in place and not circulating" do
      it "sets availability to library use only" do
        allow(item_one).to receive(:in_place?) { true }
        allow(item_one).to receive(:non_circulating?) { true }

        expect(document.material_from_barcode("FOOBAR")[:availability]).to eq("Library Use Only")
      end
    end

    context "material in place and circulating" do
      it "sets availability to available" do
        allow(item_one).to receive(:in_place?) { true }

        expect(document.material_from_barcode("FOOBAR")[:availability]).to eq("Available")
      end
    end

    context "material is missing" do
      it "sets availability to missing" do
        allow(item_one).to receive(:has_process_type?) { true }
        allow(item_one).to receive(:process_type) { "MISSING" }

        expect(document.material_from_barcode("FOOBAR")[:availability]).to eq("Missing")
      end
    end

    context "unknown" do
      it "sets availability to checked out or currently unavailable" do
        expect(document.material_from_barcode("FOOBAR")[:availability]).to eq("Checked out or currently unavailable")
      end
    end
  end

  describe "#to_sms_text" do
    context "no material items present" do
      it "does not render catalog location"  do
        document[:sms] = nil
        expect(document.to_sms_text).to be_nil
      end
    end

    context "a material item is present and selected" do
      it "renders catalog location" do
        document[:sms] = { library: "foo", location: "bar", call_number: "call_me" }
        expect(document.to_sms_text).to eq("foo bar call_me")
      end
    end
  end

  describe "#purchase_order?" do
    context "with purchase_order false" do
      let(:document) { SolrDocument.new(purchase_order: false) }

      it "should be false" do
        expect(document.purchase_order?).to be false
      end
    end

    context "with purchase_order true" do
      let(:document) { SolrDocument.new(purchase_order: true) }

      it "should be true" do
        expect(document.purchase_order?).to be true
      end
    end

    context "with no purchase_order" do
      let(:document) { SolrDocument.new({}) }

      it "should be false" do
        expect(document.purchase_order?).to be false
      end
    end
  end

  describe "#export_as_ris" do
      subject { SolrDocument.new(properties).export_as_ris }

      context "For a standard MARC Record" do
          let(:properties) do
            {
              "id" => "9618072",
              "title_statement_display" => ["Book Title"],
              "pub_date_display" => [
                "2018"
              ],
              "date_copyright_display" => 2018,
              "format" => [
                "Book"
              ],
              "language_display" => [
                "Korean"
              ],
              "call_number_display": [
                "BQ2043.K6 T757 2008"
              ]
            }
          end

          it "Starts with a valid RIS Format" do
            expect(subject).to match("TY  - BOOK\nTI  - Book Title\nY1  - 2018\nLA  - Korean\nCN  - BQ2043.K6 T757 2008\nER")
          end

          it "Contains title citation information" do
            expect(subject).to include("TI  - Book Title")
          end

          it "Contains publication date information" do
            expect(subject).to include("Y1  - 2018")
          end

          it "Contains language information" do
            expect(subject).to include("LA  - Korean")
          end

          it "Contains call number information" do
            expect(subject).to include("CN  - BQ2043.K6 T757 2008")
          end
        end
    end
end
