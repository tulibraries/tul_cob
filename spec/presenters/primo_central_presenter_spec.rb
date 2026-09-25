# frozen_string_literal: true

require "rails_helper"

RSpec.describe PrimoCentralPresenter, type: :presenter do
  let(:request) { ActionDispatch::TestRequest.create }
  let(:controller) { ApplicationController.new.tap { |c| c.request = request }.extend(Rails.application.routes.url_helpers) }
  let(:view_context) { controller.view_context }
  let(:configuration) { PrimoCentralController.new.blacklight_config }
  let(:document_data) { { "title" => "Article title", "subtitle" => "Article subtitle" } }
  let(:document) { PrimoCentralDocument.new(document_data, blacklight_config: configuration) }
  let(:presenter) { described_class.new(document, view_context, configuration) }

  describe "#label" do
    it "includes the document subtitle" do
      expect(presenter.label(:title)).to eq("Article title: Article subtitle")
    end

    context "when the document has no subtitle" do
      let(:document_data) { { "title" => "Article title" } }

      it "returns the document title" do
        expect(presenter.label(:title)).to eq("Article title")
      end
    end

    context "when the document subtitle is nil" do
      let(:document_data) { { "title" => "Article title", "subtitle" => nil } }

      it "returns the document title" do
        expect(presenter.label(:title)).to eq("Article title")
      end
    end
  end

  describe "#with_subtitle" do
    it "appends the document subtitle to the title" do
      expect(presenter.with_subtitle("Article title")).to eq("Article title: Article subtitle")
    end

    context "when the document has no subtitle" do
      let(:document_data) { { "title" => "Article title" } }

      it "returns the title unchanged" do
        expect(presenter.with_subtitle("Article title")).to eq("Article title")
      end
    end
  end

  describe "#purchase_order_button" do
    it "does not render a purchase order button" do
      expect(presenter.purchase_order_button).to be_nil
    end
  end
end
