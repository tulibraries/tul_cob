# frozen_string_literal: true

require "rails_helper"

RSpec.describe BooksSearchBuilder , type: :model do
  let(:context) { CatalogController.new }
  let(:params) { ActionController::Parameters.new(with_no_journals: true) }
  let(:search_builder) { BooksSearchBuilder.new(context) }

  subject { search_builder }

  describe "#no_journals" do
    before(:example) do
      allow(search_builder).to receive(:blacklight_params).and_return(params)
      subject.no_journals(solr_parameters)
    end

    context "default" do
      let(:solr_parameters) { Blacklight::Solr::Request.new }

      it "adds suppression to fq" do
        expect(solr_parameters["fq"]).to eq(["!format:Journal/Periodical"])
      end
    end

    context "when fq already exists" do
      let(:solr_parameters) { Blacklight::Solr::Request.new(fq: ["foo"]) }

      it "adds suppression to fq" do
        expect(solr_parameters["fq"]).to eq(["foo", "!format:Journal/Periodical"])
      end
    end

    context "when params do not include with_no_journals feature" do
      let(:params) { ActionController::Parameters.new }
      let(:solr_parameters) { Blacklight::Solr::Request.new }

      it "adds suppression to fq" do
        expect(solr_parameters["fq"]).to eq([])
      end
    end
  end
end
