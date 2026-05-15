# frozen_string_literal: true

require "rails_helper"

RSpec.describe BlacklightAdvancedSearch::RenderConstraintsOverride, type: :helper do
  describe "#guided_search" do

    example "empty search fields" do
      expect(helper.guided_search).to be_empty
    end
  end

  describe ".operator_default" do
    example "default" do
      expect(helper.operator_default(2)).to eq("contains")
    end

    example "two consecutive searches" do
      params = ActionController::Parameters.new(
        q_1: "james",
        q_2: "john",
        q_3: "david",
        operator: { "q_1" => "foo", "q_2" => "bar", "q_3" => "bum" }
      )
      allow(helper).to receive(:params).and_return(params)

      expect(helper.operator_default(2)).to eq("bar")
    end
  end

end

RSpec.describe AdvancedHelper, type: :helper do

  describe "label_tag_default_for" do
    example "basic search to search" do
      params = {
        "search_field" => "First Name",
        "q" => "james"
      }
      allow(helper).to receive(:params).and_return(params)

      expect(helper.label_tag_default_for("q_1")).to eq("james")
      expect(helper.label_tag_default_for("f_1")).to eq("First Name")
    end
  end

  describe "#basic_search_path" do
    before(:each) do
      allow(helper).to receive(:current_page?).with("/catalog/advanced") { false }
      allow(helper).to receive(:current_page?).with("/journals/advanced") { false }
      allow(helper).to receive(:current_page?).with("/articles/advanced") { false }
      allow(helper).to receive(:current_page?).with("/databases/advanced") { false }
    end

    context "on the advanced catalog search page" do
      it "renders the link to the catalog search" do
        allow(helper).to receive(:current_page?).with("/catalog/advanced") { true }
        expect(helper.basic_search_path).to eq("/catalog")
      end
    end

    context "on the advanced journals search page" do
      it "renders the link to the journals search" do
        allow(helper).to receive(:current_page?).with("/journals/advanced") { true }
        expect(helper.basic_search_path).to eq("/journals")
      end
    end

    context "on the advanced articles page" do
      it "renders the link to the articles search" do
        allow(helper).to receive(:current_page?).with("/articles/advanced") { true }
        expect(helper.basic_search_path).to eq("/articles")
      end
    end

    context "on the advanced databases page" do
      it "renders the link to the databases search" do
        allow(helper).to receive(:current_page?).with("/databases/advanced") { true }
        expect(helper.basic_search_path).to eq("/databases")
      end
    end

    context "on some unknown page" do
      it "renders the link to the everything search" do
        allow(helper).to receive(:current_page?).with("/foo/advanced") { true }
        expect(helper.basic_search_path).to eq("/catalog")
      end
    end
  end

  describe "#advanced_search_form_title" do
    before(:each) do
      allow(helper).to receive(:current_page?).with("/catalog/advanced") { false }
      allow(helper).to receive(:current_page?).with("/journals/advanced") { false }
      allow(helper).to receive(:current_page?).with("/articles/advanced") { false }
      allow(helper).to receive(:current_page?).with("/databases/advanced") { false }
    end

    context "on the advanced catalog search page" do
      it "renders the link to the catalog search" do
        allow(helper).to receive(:current_page?).with("/catalog/advanced") { true }
        expect(helper.advanced_search_form_title).to eq("Advanced Search")
      end
    end

    context "on the advanced journals search page" do
      it "renders the link to the journals search" do
        allow(helper).to receive(:current_page?).with("/journals/advanced") { true }
        expect(helper.advanced_search_form_title).to eq("Advanced Journals Search")
      end
    end

    context "on the advanced articles page" do
      it "renders the link to the articles search" do
        allow(helper).to receive(:current_page?).with("/articles/advanced") { true }
        expect(helper.advanced_search_form_title).to eq("Advanced Articles Search")
      end
    end

    context "on the advanced databases page" do
      it "renders the link to the databasees search" do
        allow(helper).to receive(:current_page?).with("/databases/advanced") { true }
        expect(helper.advanced_search_form_title).to eq("Advanced Databases Search")
      end
    end

    context "on some unknown page" do
      it "renders the link to the everything search" do
        allow(helper).to receive(:current_page?).with("/foo/advanced") { true }
        expect(helper.advanced_search_form_title).to eq("Advanced Search")
      end
    end

  end
end
