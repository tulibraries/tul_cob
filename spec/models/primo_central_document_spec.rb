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

end
