# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Blacklight::Document::Email" do
  let(:document) { SolrDocument.new(id: "1234", marc_display_raw: "foobar") }
  let(:bib_items) { [ item_one ] }

  before(:all) do
    SolrDocument.use_extension(Blacklight::Document::Email)
  end

  it "only returns values that are available in the field semantics" do
    document = SolrDocument.new(alma_mms_display: "1234", title_statement_display: "My Title")
    email_body = document.to_email_text
    expect(email_body).to match(/Title: My Title/)
    expect(email_body).not_to match(/Author/)
  end

  it "handles multi-valued fields correctly" do
    document = SolrDocument.new(alma_mms_display: "1234", title_statement_display: ["My Title", "My Alt. Title"])
    email_body = document.to_email_text
    expect(email_body).to match(/Title: My Title; My Alt. Title/)
  end

  it "is empty if there are no valid field semantics to build the email body from" do
    document = SolrDocument.new(alma_mms_display: "1234")
    expect(document.to_email_text).to eq("")
  end

  it "correctly formats contributor names" do
    document = SolrDocument.new(contributor_display: ["{\"name\":\"Pong, Chun-ho, 1969-\",\"role\":\"director, producer, screenwriter\"}",
   "{\"name\":\"Song, Kang-ho, 1967-\",\"role\":\"actor\"}",
   "{\"name\":\"Yi, Sŏn-gyun, 1975-\",\"role\":\"actor\"}"])
    expect(document.to_email_text).to eq("Contributor: Pong, Chun-ho, 1969-; Song, Kang-ho, 1967-; Yi, Sŏn-gyun, 1975-\n")
  end

  let(:item_one) { Alma::BibItem.new(
    "bib_data" => { "title" => "Hello World" },
    "holding_data" => { "call_number" => "CALL ME" },
    "item_data" => {
      "physical_material_type" => { "value" => "ANY" },
      "pid" => "FOOBAR",
      "library" => { "value" => "MAIN" },
      "location" => { "value" => "stacks" },
      "raw_library" => { "value" => "MAIN" }
    },

  ) }

  before {
    allow(document).to receive(:materials_data) { Proc.new { bib_items } }
  }

  it "includes holdings information" do
    expect(document.to_email_text).to eq("Located at: \nCharles Library - Stacks (4th floor) - CALL ME")
  end
end
