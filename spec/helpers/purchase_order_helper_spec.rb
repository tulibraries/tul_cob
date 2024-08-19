# frozen_string_literal: true

require "rails_helper"

RSpec.describe PurchaseOrderHelper, type: :helper do

  describe "#render_purchase_order_availability" do
    let(:user) { FactoryBot.build(:user) }
    let(:doc) { SolrDocument.new(purchase_order: true, id: "foo") }
    let(:can_purchase_order?) { true }
    let(:config) { CatalogController.blacklight_config }
    let(:context) { Blacklight::Configuration::Context.new(config) }
    let(:presenter) { helper.document_presenter(doc) }

    before(:each) do
      allow(helper).to receive(:link_to) { "render_login_link" }
      allow(helper).to receive(:current_user) { user }
      allow(helper).to receive(:content_tag) {}
      allow(helper).to receive(:render) {}
      allow(user).to receive(:can_purchase_order?) { can_purchase_order? }

      without_partial_double_verification do
        allow(helper).to receive(:blacklight_config) { config }
        allow(helper).to receive(:blacklight_configuration_context) { context }
      end

      helper.render_purchase_order_availability(presenter)
    end

    context "document has purchase order and user is not logged in" do
      let(:user) { nil }

      it "should render the log_in link" do
        expect(helper).to have_received(:render).with(
          partial: "purchase_order_anonymous_button",
          locals: { document: doc, link: "render_login_link" }
        )
      end
    end

    context "document has purchase order and user is not logged in and link configured to appear in button" do
      let(:user) { nil }
      let(:args) { {
        document: SolrDocument.new(purchase_order: true, id: "foo"),
        config: { with_po_link: true },
      } }

      it "should render the log_in link inside of button" do
        expect(helper).to have_received(:render).with(
          partial: "purchase_order_anonymous_button",
          locals: { document: args[:document], link: "render_login_link" }
        )
      end
    end

    context "document has purchase order and user is logged in" do
      it "should render the purchase order button" do
        expect(helper).to have_received(:content_tag).with(
          :div, "render_login_link", class: "requests-container mb-2 ms-0"
        )
      end
    end

    context "document has purchase order but user cannot purchase order" do
      let(:can_purchase_order?) { false }

      it "should render purchase allow message" do
        expect(helper).to have_received(:content_tag).with(
          :div, t("purchase_order.purchase_order_allowed"), class: "availability"
        )
      end
    end

    context "document does not have purchase order button" do
      let(:doc) { SolrDocument.new(purchase_order: false) }

      it "should not render the purchase_order_button" do
        expect(helper.render_purchase_order_availability(presenter)).to be_nil
      end
    end
  end

  describe "#render_purchase_order_show_link" do
    let(:args) { { document: SolrDocument.new(purchase_order: true, id: "foo") } }
    let(:user) { FactoryBot.build_stubbed(:user) }
    let(:can_purchase_order?) { true }

    before(:each) do
      allow(helper).to receive(:link_to) { "render_login_link" }
      allow(helper).to receive(:current_user) { user }
      allow(helper).to receive(:render_purchase_order_button) { "render_purchase_order_button" }
      allow(user).to receive(:can_purchase_order?) { can_purchase_order? }

      without_partial_double_verification do
        allow(helper).to receive(:blacklight_config) { blacklight_config }
      end

      helper.render_purchase_order_show_link(args)
    end

    context "document has purchase order and user is not logged in" do
      let(:user) { nil }

      it "should render the log in in link" do
        expect(helper.render_purchase_order_show_link(args)).to eq("render_login_link")
      end
    end

    context "document does not have purchase order" do
      let(:args) { { document: SolrDocument.new(purchase_order: false, id: "foo") } }

      it "should not render the log in in link" do
        expect(helper.render_purchase_order_show_link(args)).to be_nil
      end
    end

    context "user is logged in and cannot purchase an order" do
      let(:can_purchase_order?) { false }

      it "should not render the log in in link" do
        expect(helper.render_purchase_order_show_link(args)).to be_nil
      end
    end

    context "user is logged in and can purchase an order" do
      it "should not render the log in in link" do
        expect(helper.render_purchase_order_show_link(args)).to eq("render_purchase_order_button")
      end
    end
  end
end
