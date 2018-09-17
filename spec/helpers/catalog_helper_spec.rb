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

  describe "#render_show_doc_actions" do
    let(:blacklight_config) {
      config = Blacklight::Configuration.new
      config.show.document_actions[:sms] = "foo"
      config
    }
    let (:doc) { SolrDocument.new(format: ["Book"]) }

    before(:each) do
      without_partial_double_verification do
        allow(helper).to receive(:blacklight_config) { blacklight_config }
      end

      allow(helper).to receive(:render_filtered_partials)
      helper.render_show_doc_actions(doc) {}
    end

    context "document is type book" do
      it "does not delete the :sms action from blacklight_config" do
        expect(blacklight_config.show.document_actions).to include(:sms)
      end
    end

    context "document is multiple types including book" do
      let(:doc) { SolrDocument.new(format: ["Foo", "Book"]) }

      it "does not delete the :sms action from blacklight_config" do
        expect(blacklight_config.show.document_actions).to include(:sms)
      end
    end

    context "document is not of type book" do
      let(:doc) { SolrDocument.new(format: ["Foo"]) }

      it "deletes the :sms action from blacklight_config" do
        expect(blacklight_config.show.document_actions).to_not include(:sms)
      end
    end

    context "document is multiple types not including book" do
      let(:doc) { SolrDocument.new(format: ["Foo", "Bar"]) }

      it "deletes the :sms action from blacklight_config" do
        expect(blacklight_config.show.document_actions).to_not include(:sms)
      end
    end
  end
end
