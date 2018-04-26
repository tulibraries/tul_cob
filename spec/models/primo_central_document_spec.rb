# frozen_string_literal: true

require "rails_helper"

RSpec.describe PrimoCentralDocument, type: :model do
  let (:subject) { PrimoCentralDocument.new(doc, nil) }

  context "document direct_link contains rft.isbn = ''" do
    let(:doc) { ActiveSupport::HashWithIndifferentAccess.new(
      delivery: {
        GetIt1: [{
          "links" => [{ "link" => "http://foobar.com?rft.isbn=''" }],
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
