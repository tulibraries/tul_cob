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
  it "handles Dubin Core" do
    expect(document).to respond_to(:dublin_core_field_names)
  end

  it "handles to Marc messages" do
    expect(document).to respond_to(:to_marc)
  end
end
