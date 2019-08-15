# frozen_string_literal: true

require "rails_helper"
require "traject"
require "traject/command_line"
require "yaml"
require "pry"

RSpec.feature "Web Content" do

  feature "Web content Home Page" do
    context "publicly available pages" do
      scenario "User visits web content home page" do
        visit "/web_content"
        expect(page).to_not have_css("#facets")
      end
    end
  end

  feature "Facets" do
    let (:facets) {
      [ "Category",
      ]
    }
    context "searching shows all facets" do
      scenario "User searches catalog" do
        visit "/web_content"
        fill_in "q", with: "*"
        click_button "search"

        within("#facets") do
          all("div.panel").each_with_index do |div_panel, i|
            expect(div_panel).to have_text facets[i]
          end
        end
      end
    end
  end
end
