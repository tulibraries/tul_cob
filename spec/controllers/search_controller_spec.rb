# frozen_string_literal: true

require "rails_helper"

RSpec.describe SearchController, type: :controller do

  describe "#process_results" do
    let(:books_media_results) { BentoSearch::ConcurrentSearcher.new(:books_and_media).search("ymca").results }

    before {
      controller.send(:process_results, books_media_results)
    }

    context "regular results are present" do
      it "defines @response instance variable for the controller" do
        expect(controller.instance_variable_get(:@response)).not_to be_nil
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

        results = BentoSearch::ConcurrentSearcher.new(:books_and_media, :bad_service).search("foo").results
        expect {
          expect { controller.send(:process_results, results) }.to_not raise_error
          Honeybadger.flush
        }.to change { Honeybadger::Backend::Test.notifications[:notices].size }.by(1)

        notice = Honeybadger::Backend::Test.notifications[:notices].first
        expect(notice.error_message.encode("UTF-8")).to eq("HTTPClient::TimeoutError: HTTPClient::TimeoutError")
      end
    end
  end
end
