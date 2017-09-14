require 'rails_helper'
require 'yaml'
include ApplicationHelper

RSpec.feature "Advanced Search", type: :feature do
  let (:fixtures) {
    YAML.load_file("#{fixture_path}/features.yml")
  }

  feature "Facets" do
    let (:facets) {
      [ "Library",
        "Resource Type"
      ]
    }
    context "advanced search page displays facets" do
      scenario "User visits advanced search page" do
        visit '/advanced'
        within("#advanced-search-facets") do
          all('div.limit-input').each_with_index do |div_panel, i|
            expect(div_panel).to have_text facets[i]
          end
        end
      end
    end
  end
end
