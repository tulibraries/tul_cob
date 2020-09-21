# frozen_string_literal: true

require "rails_helper"

RSpec.describe SearchController, type: :controller do

  describe "#process_results" do
    let(:results) { BentoSearch::ConcurrentSearcher.new(:books_and_media, :cdm).search("foo").results }

    before {
      stub_request(:get, /contentdm/)
        .to_return(status: 200,
                  headers: { "Content-Type" => "application/json" },
                  body: JSON.dump(content_dm_results))
      controller.send(:process_results, results)
    }

    context "content dm and regular results are present" do

      it "defines @reponse instance variable for the controller" do
        expect(controller.instance_variable_get(:@response)).not_to be_nil
      end

      it "adds content-dm totals to facet" do
        facet_fields = controller.instance_variable_get(:@response).facet_fields
        expect(facet_fields).to include("format" => [ "digital_collections", "415" ])
      end
    end

    context "only cdm results present" do
      let(:results) { BentoSearch::ConcurrentSearcher.new(:cdm).search("foo").results }

      it "should still remove cdm results from bento results" do
        expect(results[:cdm]).to be_nil
      end
    end

    context "one or more concurrent searches fails" do

      it "should not raise the error when a search has failed, just tell HoneyBadger" do
        Object.const_set("BadService", Class.new {
                           include BentoSearch::SearchEngine
                           def search_implementation(args)
                             raise HTTPClient::TimeoutError.new
                           end
                         })

        BentoSearch.register_engine("bad_service") do |conf|
          conf.engine = "BadService"
        end

        results = BentoSearch::ConcurrentSearcher.new(:books_and_media, :cdm, :bad_service).search("foo").results
        expect {
          expect { controller.send(:process_results, results) }.to_not raise_error
          Honeybadger.flush
        }.to change(Honeybadger::Backend::Test.notifications[:notices], :size).by(1)
        expect(Honeybadger::Backend::Test.notifications[:notices].first.error_message).to eq("HTTPClient::TimeoutError: HTTPClient::TimeoutError")
      end
    end
  end

  def content_dm_results
    { "results" => { "pager" => { "total" => "415" } } }
  end
end
