# frozen_string_literal: true

require "rails_helper"

RSpec.describe PrimoSearchService, api: true do
  subject { service }

  let(:context) { { whatever: :value } }

  let(:service) { described_class.new(config: blacklight_config, user_params: user_params, **context) }

  let(:repository) { Blacklight::PrimoCentral::Repository.new(blacklight_config) }

  let(:user_params) { {}.with_indifferent_access }

  let(:blacklight_config) { PrimoCentralController.blacklight_config }


  before do
    allow(service).to receive(:repository).and_return(repository)
  end

  describe "#search_builder_class" do
    subject { service.send(:search_builder_class) }

    it "defaults to the value in the config" do
      expect(subject).to eq Blacklight::PrimoCentral::SearchBuilder
    end

    context "when the search_builder_class is passed in" do
      let(:klass) { double("Search builder") }

      let(:service) { described_class.new(config: blacklight_config, user_params: user_params, search_builder_class: klass) }

      it "uses the passed value" do
        expect(subject).to eq klass
      end
    end
  end

  describe "#fetch" do
    it "handles more than 10 ids and separates out not found" do
      ids = [ "TN_pubmed_central5894087",
              "TN_sage_s10_1177_0011392114556593",
              "TN_tayfranc10-dot-1080-slash-17524032-dot-2018-dot-1435557",
              "doaj_soai_doaj_org_article_b354b3aa4a7c4b86adbba22d2d4c6358",
              "emerald_s10-dot-1108-slash-SRJ-07-2014-0095",
              "gale_ofa569155838",
              "pubtecwhp-slash-ev-slash-1992-slash-00000001-slash-00000002-slash-art00006",
              "sage_s10_1177_0276146714535932",
              "sage_s10_7227_IJS_0011",
              "sciversesciencedirect_elsevierS0016-7185(11)00044-3",
              "sciversesciencedirect_elsevierS0016-7185(15)00270-5",
              "sciversesciencedirect_elsevierS0959-6526(17)31298-2",
              "sciversesciencedirect_elsevierS0969-6989(15)30150-8"]

      VCR.use_cassette("primo_search_service") do
        (_, docs) = service.fetch(ids)
        expect(docs.count).to eq(13)

        # Handles the unfound id correctly.
        doc = docs.find { |d| d.id == "emerald_s10-dot-1108-slash-SRJ-07-2014-0095" }

        expect(doc["ajax"]).to eq(true)
      end
    end
  end

end
