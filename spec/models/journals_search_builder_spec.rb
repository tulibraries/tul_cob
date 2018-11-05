# frozen_string_literal: true

require "rails_helper"

RSpec.describe JournalsSearchBuilder , type: :model do
  let(:context) { CatalogController.new }
  let(:params) { ActionController::Parameters.new }
  let(:search_builder) { JournalsSearchBuilder.new(context) }
  let(:solr_parameters) { Blacklight::Solr::Request.new(fq: []) }
  let(:user) { FactoryBot.create(:user) }

  before(:each) do
    allow(context).to receive(:current_user) { user }
  end

  subject { search_builder }

  it "Should include a journals_facet search preprocessor" do
    expect(subject.default_processor_chain).to include(:journals_facet)
  end

  describe "#journals_facet" do
    before(:each) do
      subject.journals_facet(solr_parameters)
    end

    it "adds a journals format filter" do
      expect(solr_parameters["fq"]).to eq(["{!term f=format}Journal/Periodical"])
    end

    it "is idempotent" do
      subject.journals_facet(solr_parameters)
      expect(solr_parameters["fq"]).to eq(["{!term f=format}Journal/Periodical"])
    end

    context "fq not explicitly set" do
      let(:solr_parameters) { Blacklight::Solr::Request.new }

      it "stil works just fine" do
        expect(solr_parameters["fq"]).to include("{!term f=format}Journal/Periodical")
      end
    end
  end
end
