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

  describe "#render_advanced_search_link" do
    before(:each) do
      allow(helper).to receive(:params) { { q: "foo", controller: "bar" } }
    end

    context "not on advanced page" do
      it "renders the link to the advanced form" do
        link = "<a class=\"advanced_search\" id=\"advanced_search\" href=\"/advanced?q=foo\">Advanced Catalog Search</a>"
        expect(helper.render_advanced_search_link).to eq(link)
      end
    end

    context "on the advanced page" do
      it "renders a link to the basic search page" do
        allow(helper).to receive(:current_page?) { true }
        link = "<a class=\"advanced_search\" id=\"basic_search\" href=\"/\">Basic Search</a>"
        expect(helper.render_advanced_search_link).to eq(link)
      end
    end
  end
end
