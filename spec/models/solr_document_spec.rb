# frozen_string_literal: true

require "rails_helper"

RSpec.describe SolrDocument, type: :model do
  let(:document) { SolrDocument.new(id: "991012041239703811", marc_display_raw: "foobar") }

  it "handles Email" do
    expect(document).to respond_to(:to_email_text)
  end

  it "handles to Marc messages" do
    expect(document).to respond_to(:to_marc)
  end

  let(:bib_items) { [ item_one ] }

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

  describe "#is_suppressed?" do
    context "document does not have a supress_items_b field" do
      it "returns false" do
        expect(document.is_suppressed?).to be false
      end
    end

    context "document has a supress_items_b field value false" do
      it "returns false" do
        expect(document.is_suppressed?).to be false
      end
    end

    context "document has a supress_items_b field value true" do
      it "raises a  Blacklight::Exceptions::RecordNotFound error" do
        expect { SolrDocument.new(id: "1", suppress_items_b: true) }.to raise_error(Blacklight::Exceptions::RecordNotFound)
      end
    end
  end

  describe "#document_items" do
    context "filters out empty items" do
      let(:document) { SolrDocument.new({}) }

      it "returns an empty array" do
        expect(document.document_items).to eq([])
      end
    end
  end

  describe "#document_items_grouped" do
    context "groups by library" do

      let(:document) { SolrDocument.new("items_json_display" =>
        [{ "item_pid" => "12345",
        "item_policy" => "5",
        "permanent_library" => "AMBLER",
        "permanent_location" => "media",
        "current_library" => "AMBLER",
        "current_location" => "media",
        "call_number" => "DVD 13 A165",
        "holding_id" => "22237957750003811" }]
      )}

      it "uses the library as a key" do
        expect(document.document_items_grouped).to eq(
          "Ambler Campus Library" =>
            { "Media" =>
              [{ "call_number" => "DVD 13 A165",
              "call_number_display" => "DVD 13 A165",
              "current_library" => "AMBLER",
              "current_location" => "media",
              "holding_id" => "22237957750003811",
              "item_pid" => "12345",
              "item_policy" => "5",
              "library" => "Ambler Campus Library",
              "location" => "Media",
              "permanent_library" => "AMBLER",
              "permanent_location" => "media" }]
            })
      end
    end

    context "groups by location" do
      let(:document) { SolrDocument.new("items_json_display" =>
        [{ "item_pid" => "23245366030003811",
          "item_policy" => "0",
          "permanent_library" => "KARDON",
          "permanent_location" => "p_remote",
          "current_library" => "KARDON",
          "current_location" => "p_remote",
          "call_number_type" => "0",
          "call_number" => "N5220.K7",
          "holding_id" => "22245366050003811",
          "material_type" => "BOOK" },
         { "item_pid" => "23245366040003811",
          "item_policy" => "0",
          "permanent_library" => "KARDON",
          "permanent_location" => "p_remote",
          "current_library" => "KARDON",
          "current_location" => "p_remote",
          "call_number_type" => "0",
          "call_number" => "N5220.K7",
          "holding_id" => "22245366050003811",
          "material_type" => "BOOK" }]
        )}

      it "uses the location as a key" do
        expect(document.document_items_grouped).to eq("Remote Storage" =>
          { "Remote Storage - Charles" =>
            [{ "call_number" => "N5220.K7",
              "call_number_display" => "N5220.K7",
              "call_number_type" => "0",
              "current_library" => "KARDON",
              "current_location" => "p_remote",
              "holding_id" => "22245366050003811",
              "item_pid" => "23245366030003811",
              "item_policy" => "0",
              "library" => "Remote Storage",
              "location" => "Remote Storage - Charles",
              "material_type" => "BOOK",
              "permanent_library" => "KARDON",
              "permanent_location" => "p_remote" },
              { "call_number" => "N5220.K7",
              "call_number_display" => "N5220.K7",
              "call_number_type" => "0",
              "current_library" => "KARDON",
              "current_location" => "p_remote",
              "holding_id" => "22245366050003811",
              "item_pid" => "23245366040003811",
              "item_policy" => "0",
              "library" => "Remote Storage",
              "location" => "Remote Storage - Charles",
              "material_type" => "BOOK",
              "permanent_library" => "KARDON",
              "permanent_location" => "p_remote" }] })
      end
    end

    context "groups by multiple locations" do
      let(:document) { SolrDocument.new("items_json_display" =>
        [{ "item_pid" => "23280623530003811",
        "item_policy" => "0",
        "description" => "2001",
        "permanent_library" => "GINSBURG",
        "permanent_location" => "stacks",
        "current_library" => "GINSBURG",
        "current_location" => "stacks",
        "call_number_type" => "2",
        "call_number" => "WB 39 W319",
        "holding_id" => "22280623590003811",
        "material_type" => "ISSUE" },
        { "item_pid" => "23280623450003811",
        "item_policy" => "0",
        "description" => "2014",
        "permanent_library" => "GINSBURG",
        "permanent_location" => "stacks",
        "current_library" => "GINSBURG",
        "current_location" => "stacks",
        "call_number_type" => "2",
        "call_number" => "WB 39 W319",
        "holding_id" => "22280623590003811",
        "material_type" => "ISSUE" },
        { "item_pid" => "23468827100003811",
        "item_policy" => "16",
        "description" => "2020",
        "permanent_library" => "GINSBURG",
        "permanent_location" => "reserve",
        "current_library" => "GINSBURG",
        "current_location" => "reserve",
        "call_number_type" => "2",
        "call_number" => "WB 39 W319",
        "holding_id" => "22280623440003811",
        "material_type" => "BOOK" }]
      )}

      it "uses the location as a key" do
        expect(document.document_items_grouped).to eq("Ginsburg Health Science Library" =>
          { "Reserves" =>
            [{ "call_number" => "WB 39 W319",
              "call_number_display" => "WB 39 W319",
              "call_number_type" => "2",
              "current_library" => "GINSBURG",
              "current_location" => "reserve",
              "description" => "2020",
              "holding_id" => "22280623440003811",
              "item_pid" => "23468827100003811",
              "item_policy" => "16",
              "library" => "Ginsburg Health Science Library",
              "location" => "Reserves",
              "material_type" => "BOOK",
              "permanent_library" => "GINSBURG",
              "permanent_location" => "reserve" }],
            "Stacks" =>
              [{ "call_number" => "WB 39 W319",
              "call_number_display" => "WB 39 W319",
              "call_number_type" => "2",
              "current_library" => "GINSBURG",
              "current_location" => "stacks",
              "description" => "2001",
              "holding_id" => "22280623590003811",
              "item_pid" => "23280623530003811",
              "item_policy" => "0",
              "library" => "Ginsburg Health Science Library",
              "location" => "Stacks",
              "material_type" => "ISSUE",
              "permanent_library" => "GINSBURG",
              "permanent_location" => "stacks" },
              { "call_number" => "WB 39 W319",
              "call_number_display" => "WB 39 W319",
              "call_number_type" => "2",
              "current_library" => "GINSBURG",
              "current_location" => "stacks",
              "description" => "2014",
              "holding_id" => "22280623590003811",
              "item_pid" => "23280623450003811",
              "item_policy" => "0",
              "library" => "Ginsburg Health Science Library",
              "location" => "Stacks",
              "material_type" => "ISSUE",
              "permanent_library" => "GINSBURG",
              "permanent_location" => "stacks" }]
            })
      end

      it "sorts location alphabetically by default" do
        expect(document.document_items_grouped["Ginsburg Health Science Library"].keys).to eq(["Reserves", "Stacks"])
      end

    end

    context "items are sorted by library name with Charles first" do
      let(:document) { SolrDocument.new("items_json_display" =>
      [{ "item_pid" => "23239405700003811",
          "item_policy" => "0",
          "permanent_library" => "AMBLER",
          "permanent_location" => "stacks",
          "current_library" => "AMBLER",
          "current_location" => "stacks",
          "call_number_type" => "0",
          "call_number" => "F159.P7 C66 2003",
          "holding_id" => "22239405730003811",
          "availability" => "<span class=\"check\"></span>Available" },
          { "item_pid" => "23239405700003811",
          "item_policy" => "0",
          "permanent_library" => "ASRS",
          "permanent_location" => "bookbot",
          "current_library" => "ASRS",
          "current_location" => "bookbot",
          "call_number_type" => "0",
          "call_number" => "F159.P7 C66 2003",
          "holding_id" => "22239405730003811",
          "availability" => "<span class=\"check\"></span>Available" },
          { "item_pid" => "23239405740003811",
          "item_policy" => "0",
          "permanent_library" => "MAIN",
          "permanent_location" => "stacks",
          "current_library" => "MAIN",
          "current_location" => "stacks",
          "call_number_type" => "0",
          "call_number" => "F159.P7 C66 2003",
          "holding_id" => "22239405750003811",
          "availability" => "<span class=\"check\"></span>Available" }]
          )}

      it "returns Charles first, then Ambler" do
        expect(document.document_items_grouped.keys).to eq(["Charles Library", "Ambler Campus Library"])
      end
    end

    context "Items are ordered by call number after location" do
      let(:document) { SolrDocument.new("items_json_display" =>
      [{ "item_pid" => "23242235660003811",
          "item_policy" => "12",
          "description" => "1992-94",
          "permanent_library" => "MAIN",
          "permanent_location" => "stacks",
          "current_library" => "AMBLER",
          "current_location" => "stacks",
          "library" => "Ambler Campus Library",
          "location" => "Stacks",
          "call_number_type" => "0",
          "call_number" => "MT655.P45x",
          "call_number_display" => "MT655.P45x",
          "holding_id" => "22242235730003811",
          "availability" => "<span class=\"check\"></span>Library Use Only" },
         { "item_pid" => "23242235720003811",
          "item_policy" => "12",
          "description" => "1983-1986",
          "permanent_library" => "MAIN",
          "permanent_location" => "stacks",
          "current_library" => "AMBLER",
          "current_location" => "stacks",
          "library" => "Ambler Campus Library",
          "location" => "Stacks",
          "call_number_type" => "0",
          "call_number" => "HF5006 .I614",
          "call_number_display" => "HF5006 .I614",
          "holding_id" => "22242235730003811",
          "availability" => "<span class=\"check\"></span>Library Use Only" },
         { "item_pid" => "23242235710003811",
          "item_policy" => "12",
          "description" => "1987-89",
          "permanent_library" => "MAIN",
          "permanent_location" => "stacks",
          "current_library" => "AMBLER",
          "current_location" => "stacks",
          "library" => "Ambler Campus Library",
          "location" => "Stacks",
          "call_number_type" => "0",
          "call_number" => "AC1 .G72",
          "call_number_display" => "AC1 .G72",
          "holding_id" => "22242235730003811",
          "availability" => "<span class=\"check\"></span>Library Use Only" }]
        )}

      it "returns copies for each library by call number" do
        sorted_call_numbers = document.document_items_grouped["Ambler Campus Library"]["Stacks"].map { |item| item["call_number_display"] }
        expect(sorted_call_numbers).to eq(["AC1 .G72", "HF5006 .I614", "MT655.P45x"])
      end
    end

    context "Items are ordered by description after call number" do
      let(:document) { SolrDocument.new("items_json_display" =>
      [{ "item_pid" => "23242235660003811",
          "item_policy" => "12",
          "description" => "v.55, no.5 (Nov. 2017)",
          "permanent_library" => "MAIN",
          "permanent_location" => "stacks",
          "current_library" => "AMBLER",
          "current_location" => "stacks",
          "library" => "Ambler Campus Library",
          "location" => "Stacks",
          "call_number_type" => "0",
          "call_number" => "MT655.P45x",
          "call_number_display" => "MT655.P45x",
          "holding_id" => "22242235730003811" },
         { "item_pid" => "23242235720003811",
          "item_policy" => "12",
          "description" => "v.53 (2016)",
          "permanent_library" => "MAIN",
          "permanent_location" => "stacks",
          "current_library" => "AMBLER",
          "current_location" => "stacks",
          "library" => "Ambler Campus Library",
          "location" => "Stacks",
          "call_number_type" => "0",
          "call_number" => "MT655.P45x",
          "call_number_display" => "MT655.P45x",
          "holding_id" => "22242235730003811" },
         { "item_pid" => "23242235710003811",
          "item_policy" => "12",
          "description" => "v.42 (2004)",
          "permanent_library" => "MAIN",
          "permanent_location" => "stacks",
          "current_library" => "AMBLER",
          "current_location" => "stacks",
          "library" => "Ambler Campus Library",
          "location" => "Stacks",
          "call_number_type" => "0",
          "call_number" => "MT655.P45x",
          "call_number_display" => "MT655.P45x",
          "holding_id" => "22242235730003811" }]
        )}

      it "returns copies for each library by description" do
        sorted_descriptions = document.document_items_grouped["Ambler Campus Library"]["Stacks"].map { |item| item["description"] }
        expect(sorted_descriptions).to eq(["v.42 (2004)", "v.53 (2016)", "v.55, no.5 (Nov. 2017)"])
      end
    end
  end

  describe "#library(item)" do
    context "item is in temporary library" do
      let(:item) { { "current_library" => "RES_SHARE" } }

      it "displays temporary library" do
        expect(document.library(item)).to eq "RES_SHARE"
      end
    end

    context "item is NOT in temporary library" do
      let(:item) { { "permanent_library" => "MAIN" } }

      it "displays library" do
        expect(document.library(item)).to eq "MAIN"
      end
    end
  end

  describe "#alternative_call_number(item)" do
    context "item has an alternate call number" do
      let(:item) { { "alt_call_number" => "alternate call number" } }

      it "displays alternate call number" do
        expect(document.alternative_call_number(item)).to eq "alternate call number"
      end
    end

    context "item does NOT have an alternate call number" do
      let(:item) { { "call_number" => "regular call number" } }

      it "does NOT display alternate call number" do
        expect(document.alternative_call_number(item)).to eq "regular call number"
      end
    end
  end

  describe "#missing_or_lost?" do
    context "an item is missing" do
      let(:document) { SolrDocument.new("items_json_display" =>
        [{ "item_pid" => "23237957740003811",
        "item_policy" => "5",
        "permanent_library" => "AMBLER",
        "permanent_location" => "media",
        "current_library" => "AMBLER",
        "current_location" => "media",
        "call_number" => "DVD 13 A165",
        "holding_id" => "22237957750003811",
        "process_type" => "MISSING" }]
        )}

      it "correctly rejects missing item" do
        expect(document.document_items).to eq([])
      end
    end

    context "an item is lost" do
      let(:document) { SolrDocument.new("items_json_display" =>
        [{ "item_pid" => "23237957740003811",
        "item_policy" => "5",
        "permanent_library" => "AMBLER",
        "permanent_location" => "media",
        "current_library" => "AMBLER",
        "current_location" => "media",
        "call_number" => "DVD 13 A165",
        "holding_id" => "22237957750003811",
        "process_type" => "LOST_LOAN_AND_PAID" }]
        )}

      it "correctly rejects lost item" do
        expect(document.document_items).to eq([])
      end
    end

    context "an item is not missing or lost" do
      let(:document) { SolrDocument.new("items_json_display" =>
        [{ "item_pid" => "23237957740003811",
        "item_policy" => "5",
        "permanent_library" => "AMBLER",
        "permanent_location" => "media",
        "current_library" => "AMBLER",
        "current_location" => "media",
        "call_number" => "DVD 13 A165",
        "holding_id" => "22237957750003811",
        "process_type" => "LOAN" }]
        )}

      it "does not filter out item" do
        expect(document.document_items).to be_present
      end
    end
  end

  describe "unwanted library" do

    context "an item is an unwanted library" do
      let(:document) { SolrDocument.new("items_json_display" =>
        [{ "item_pid" => "23237957740003811",
        "item_policy" => "5",
        "permanent_library" => "AMBLER",
        "permanent_location" => "stacks",
        "current_library" => "EMPTY",
        "call_number" => "DVD 13 A165",
        "holding_id" => "22237957750003811" }]
        )}

      it "correctly rejects unwanted library" do
        expect(document.document_items).to eq([])
      end
    end

    context "an item is an unwanted location" do
      let(:document) { SolrDocument.new("items_json_display" =>
        [{ "item_pid" => "23237957740003811",
        "item_policy" => "5",
        "permanent_library" => "AMBLER",
        "permanent_location" => "techserv",
        "current_library" => "AMBLER",
        "current_location" => "techserv",
        "call_number" => "DVD 13 A165",
        "holding_id" => "22237957750003811",
        "process_type" => "LOAN" }]
        )}

      it "correctly rejects unwanted location" do
        expect(document.document_items).to eq([])
      end
    end

    context "an item is not in an unwanted location" do
      let(:document) { SolrDocument.new("items_json_display" =>
        [{ "item_pid" => "23237957740003811",
        "item_policy" => "5",
        "permanent_library" => "AMBLER",
        "permanent_location" => "media",
        "current_library" => "AMBLER",
        "current_location" => "media",
        "call_number" => "DVD 13 A165",
        "holding_id" => "22237957750003811" }]
        )}

      it "does not filter item" do
        expect(document.document_items).to be_present
      end
    end
  end

  describe "libkey_journals_url" do
    context "issn not present" do
      it "returns a nil" do
        expect(document.libkey_journals_url).to be_nil
        expect(document.libkey_journals_url_enabled?).to be false
      end
    end

    context "issn present" do
      let(:document) { SolrDocument.new({ "issn_display" => ["12345678"] }) }

      it "returns Browzine web link" do
        stub_request(:get, /search/)
          .to_return(status: 200,
                    headers: { "Content-Type" => "application/json" },
                    body: JSON.dump(data: [
                      {
                          browzineEnabled: true,
                          browzineWebLink: "https://browzine.com"
                      }
                  ]))

        expect(document.libkey_journals_url).to eq("https://browzine.com")
        expect(document.libkey_journals_url_enabled?).to be true

      end

      it "Browzine not enabled" do
        stub_request(:get, /search/)
          .to_return(status: 200,
                    headers: { "Content-Type" => "application/json" },
                    body: JSON.dump(data: [
                      {
                          browzineEnabled: false
                      }
                  ]))

        expect(document.libkey_journals_url).to be_nil
        expect(document.libkey_journals_url_enabled?).to be false

      end
    end

  end

  describe "describe #sanitize_id" do
    context "id is not valid" do
      it "returns nil" do
        expect(SolrDocument.sanitize_id(nil)).to be_nil
        expect(SolrDocument.sanitize_id("bash  -c rm -fR /")).to be_nil
        expect(SolrDocument.sanitize_id(1343)).to be_nil
      end
    end

    context "id is valid" do
      it "returns an id" do
        expect(SolrDocument.sanitize_id("doc-991032926439703811")).to eq("991032926439703811")
        expect(SolrDocument.sanitize_id("991032926439703811")).to eq("991032926439703811")
        expect(SolrDocument.sanitize_id(991032926439703811)).to eq("991032926439703811")
      end
    end
  end

end
