require 'rails_helper'
require 'solr_wrapper'
require 'traject'
require 'traject/command_line'

RSpec.feature "Indices", type: :feature do
  SOLR_INSTANCE = SolrWrapper.default_instance({})
  before(:all) {
    SOLR_INSTANCE.start
    Traject::CommandLine.new(["-c",
                              "app/models/traject_indexer.rb",
                              File.join("spec", "fixtures", "marc_fixture")]).execute
  }
  after(:all) { SOLR_INSTANCE.stop }

  context "publicly available pages" do
    scenario "User visits home page" do
      visit '/'
      expect(page).to have_text("Welcome!")
    end

    scenario "User visits a document" do
      visit 'catalog/991012177509703811'
      expect(page).to have_text("Academic freedom in an age of conformity")
    end
  end
end
