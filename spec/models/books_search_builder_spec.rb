# frozen_string_literal: true

require "rails_helper"

RSpec.describe BooksSearchBuilder , type: :model do
  let(:context) { CatalogController.new }
  let(:params) { ActionController::Parameters.new }
  let(:search_builder) { BooksSearchBuilder.new(context) }
  let(:solr_parameters) { Blacklight::Solr::Request.new(fq: []) }

  subject { search_builder }

  it "Should include a books_facet search preprocessor" do
    expect(subject.default_processor_chain).to include(:books_facet)
  end

  describe "#books_facet" do
    before(:each) do
      subject.books_facet(solr_parameters)
    end

    it "adds a books format filter" do
      expect(solr_parameters["fq"]).to eq(["{!term f=format}Book"])
    end

    it "is idempotent" do
      subject.books_facet(solr_parameters)
      expect(solr_parameters["fq"]).to eq(["{!term f=format}Book"])
    end

    context "fq not explicitly set" do
      let(:solr_parameters) { Blacklight::Solr::Request.new }

      it "stil works just fine" do
        expect(solr_parameters["fq"]).to include("{!term f=format}Book")
      end
    end
  end
end
