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

  describe "#render_availability" do
    let(:doc) { SolrDocument.new(purchase_order: true) }
    let(:presenter) { CatalogIndexPresenter.new(doc, self) }
    let(:blacklight_config) { CatalogController.blacklight_config }

    before do
      allow(presenter).to receive(:purchase_order_button) { "purchase_order_button" }
      allow(helper).to receive(:render) { "availability_section" }
      without_partial_double_verification do
        allow(helper).to receive(:blacklight_config) { blacklight_config }
      end
    end

    context "document has purchase order" do
      it "should render the purchase order button" do
        expect(helper.render_availability(doc, presenter)).to eq("purchase_order_button")
      end
    end

    context "document does not have purchase order button" do
      let(:doc) { SolrDocument.new(purchase_order: false) }
      it "should not render the purchase_order_button" do
        expect(helper.render_availability(doc, presenter)).to eq("availability_section")
      end
    end
  end

  describe "#render_email_form_field" do
    let(:current_user) { OpenStruct.new(email: nil) }

    before do
      allow(helper).to receive(:current_user) { current_user }
      allow(helper).to receive(:render) { "render_email_form_field" }
    end

    context "user does not have email" do
      it "renders the email field" do
        expect(helper.render_email_form_field).to eq("render_email_form_field")
      end
    end

    context "user has email" do
      let(:current_user) { OpenStruct.new(email: "foo") }

      it "does not render the email form field" do
        expect(helper.render_email_form_field).to be_nil
      end
    end

  end
end
