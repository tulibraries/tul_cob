# frozen_string_literal: true

require "rails_helper"

RSpec.describe PrimoAdvancedHelper, type: :helper do
  describe "#articles_advanced_search_link" do
    before(:each) do
      helper.instance_variable_set(:@search_state,
        "q" => "foo", "page" => "3")
    end

    context "not on advanced page" do
      it "renders the link to the advanced form" do
        link = "<a class=\"advanced_search\" id=\"articles_advanced_search\" href=\"/articles_advanced?q=foo\">Advanced Articles Search</a>"
        expect(helper.articles_advanced_search_link).to eq(link)
      end
    end

    context "on the advanced page" do
      it "renders a link to the basic search page" do
        allow(helper).to receive(:current_page?) { true }
        link = "<a class=\"advanced_search\" id=\"articles_basic_search\" href=\"/articles\">Basic Search</a>"
        expect(helper.articles_advanced_search_link).to eq(link)
      end
    end
  end
end
