# frozen_string_literal: true

require "rails_helper"

RSpec.describe PrimoCentralDocument, type: :model do
  let (:subject) { PrimoCentralDocument.new(doc, nil) }

  describe "#has_direct_link?" do
    context "document is completely empty" do
      let(:doc) { Hash.new }

      it "verifies there is no direct_link" do
        expect(subject.has_direct_link?).to be(false)
      end
    end

    context "document has a direct_link" do
      let(:doc) { ActiveSupport::HashWithIndifferentAccess.new(
        delivery: { availability: ["fulltext_linktorsrc"] }
      )}

      it "verifies that document has a direct_link" do
        expect(subject.has_direct_link?).to be(true)
      end
    end

    context "document does not have a direct link" do
      let(:doc) { ActiveSupport::HashWithIndifferentAccess.new(
        delivery: { availability: ["foobar"] }
      )}

      it "should verifies there is no direct_link" do
        expect(subject.has_direct_link?).to be(false)
      end
    end
  end

  describe "#ajax?" do
    context "document is empty" do
      let(:doc) { Hash.new }

      it "defaults to false" do
        expect { subject.ajax? }.to be(false)
      end
    end

    context "document sets ajax value to true" do
      let(:doc) { ActiveSupport::HashWithIndifferentAccess.new(
        ajax: true
      )}

      it "returns true" do
        expect(subject.ajax?)
      end
    end

    context "document sets ajax value to 'true'" do
      let(:doc) { ActiveSupport::HashWithIndifferentAccess.new(
        ajax: "true"
      )}

      it "returns true" do
        expect(subject.ajax?)
      end
    end

    context "document sets ajax to non true" do
      let(:doc) { ActiveSupport::HashWithIndifferentAccess.new(
        ajax: nil
      )}

      it "returns false" do
        expect(subject.ajax?).to be(false)
      end
    end
  end

  describe "#ajax_url" do
    context "document is empty" do
      let(:doc) { Hash.new }

      it "fails if no id is defined" do
        expect { subject.ajax_url }.to raise_error(ActionController::UrlGenerationError)
      end
    end

    context "document is empty but has id" do
      let(:doc) { ActiveSupport::HashWithIndifferentAccess.new(
        pnxId: "0"
      )}

      it "returns a path for ajax endpoint with default counter" do
        expect(subject.ajax_url).to eq("/articles/0/index_item?document_counter=0")
      end
    end
  end

  context "document direct_link contains rft.isbn = ''" do
    let(:doc) { ActiveSupport::HashWithIndifferentAccess.new(
      delivery: {
        GetIt1: [{
          "links" => [{ "link" => "http://foobar.com?rft.isbn=" }],
        }] }) }
    it "sets @doc['isbn'] to nil" do
      expect(subject["isbn"]).to be_nil
    end
  end

  context "document direc_link contains a regular value" do
    let(:doc) { ActiveSupport::HashWithIndifferentAccess.new(
      delivery: {
        GetIt1: [{
          "links" => [{ "link" => "http://foobar.com?rft.isbn=a" }],
        }] }) }
    it "sets @doc['isbn'] to [a]" do
      expect(subject["isbn"]).to eq(["a"])
    end
  end
end
