# frozen_string_literal: true

require "rails_helper"

# Specs in this file have access to a helper object that includes
# the CatalogHelper. For example:
#
# describe CatalogHelper do
#   describe "string concat" do
#     it "concats two strings with spaces" do
#       expect(helper.concat_strings("this","that")).to eq("this that")
#     end
#   end
# end

RSpec.describe CatalogHelper, type: :helper do
  describe "#isbn_data_attribute" do
    context "document contains an isbn" do
      let(:document) { { isbn_display: ["123456789"] } }
      it "returns the data-isbn string" do
        expect(isbn_data_attribute(document)).to eql "data-isbn=123456789"
      end
    end

    context "document contains multiple isbn" do
      let(:document) { { isbn_display: ["23445667890", "123456789"] } }
      it "returns the data-isbn string" do
        expect(isbn_data_attribute(document)).to eql "data-isbn=23445667890,123456789"
      end
    end

    context "document contains an isbn" do
      let(:document) { {} }
      it "returns the data-isbn string" do
        expect(isbn_data_attribute(document)).to be_nil
      end
    end
  end

  describe "#grouped_citations" do
    it "sends all the given document citations to the grouped_citations method of the Citation class" do
      documents = [
        double("Document", citations: :abc),
        double("Document", citations: :def)
      ]
      expect(Citation).to receive(:grouped_citations).with([:abc, :def])
      grouped_citations(documents)
    end
  end
  
  describe "#render_marc_view" do
    let(:doc) { OpenStruct.new(to_marc: "foo") }

    before(:each) {
      helper.instance_variable_set(:@document, doc)
      allow(helper).to receive(:render) {}
      helper.render_marc_view
    }

    context "document responds to to_marc" do
      it "renders the marc_view template" do
        expect(helper).to have_received(:render).with("marc_view")
      end
    end

    context "document does not respond to to_marc" do
      let(:doc) { double }

      it "renders a default no_marc ouput" do
        expect(helper).to_not have_received(:render)
        expect(helper.render_marc_view).to eq(helper.t("blacklight.search.librarian_view.empty"))
      end
    end
  end
end
