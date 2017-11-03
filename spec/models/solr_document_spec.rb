# frozen_string_literal: true

require "rails_helper"

RSpec.describe SolrDocument, type: :model do
  let(:document) { SolrDocument.new }

  it "handles Email" do
    expect(document).to respond_to(:to_email_text)
  end
  it "handles SMS" do
    expect(document).to respond_to(:to_sms_text)
  end
  it "handles Dubin Core" do
    expect(document).to respond_to(:dublin_core_field_names)
  end
end
