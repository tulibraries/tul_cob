# frozen_string_literal: true

require "rails_helper"

RSpec.describe BookmarkHelper, type: :helper do

  def mock_response(args)
    current_page = args[:current_page] || 1
    per_page = args[:rows] || args[:per_page] || 10
    total = args[:total]
    mock_docs = (1..total).to_a.map { {}.with_indifferent_access }

    mock_response = Kaminari.paginate_array(mock_docs).page(current_page).per(per_page)

    mock_response
  end

  describe "#index_controller" do
    context "no document or counter provided" do
      it "returns nil" do
        expect(helper.index_controller()).to be_nil
      end
    end

    context "document that does not have ajax? method" do
      it "returns nil" do
        doc = SolrDocument.new({}, nil)
        expect(helper.index_controller(doc)).to be_nil
      end
    end

    context "document that does have solr ajax and is not ajax ready" do
      it "returns nil" do
        doc = PrimoCentralDocument.new({ "ajax" => false }, nil)
        expect(helper.index_controller(doc)).to be_nil
      end
    end

    context "document is ajax ready" do
      doc = PrimoCentralDocument.new({ "pnxId" => "0", "ajax" => true }, nil)

      it "returns string that sets stimulus controller and data attributes" do
        expected = "data-controller=index data-index-url=/articles/0/index_item?document_counter=0"
        expect(helper.index_controller(doc)).to eq(expected)
      end

      it "correctly sets the document counter if pased" do
        expected = "data-controller=index data-index-url=/articles/0/index_item?document_counter=1"
        expect(helper.index_controller(doc, 1)).to eq(expected)
      end
    end
  end

  describe "current_entries_info" do
    it "with no results" do
      @response = mock_response total: 0
      expect(current_entries_info(@response)).to eq "0 - 0"
    end
    it "with one result" do
      @response = mock_response total: 1
      expect(current_entries_info(@response)).to eq "1 - 1"
    end
    it "with one page of results" do
      @response = mock_response total: 8
      expect(current_entries_info(@response)).to eq "1 - 8"
    end
    it "first page of multiple results" do
      @response = mock_response total: 15, per_page: 10
      expect(current_entries_info(@response)).to eq "1 - 10"
    end
    it "second page of multiple results" do
      @response = mock_response total: 47, per_page: 10, current_page: 2
      expect(current_entries_info(@response)).to eq "11 - 20"
    end
    it "last page of multiple results" do
      @response = mock_response total: 47, per_page: 10, current_page: 5
      expect(current_entries_info(@response)).to eq "41 - 47"
    end
  end
end
