require 'rails_helper'
require 'solr_wrapper'

RSpec.feature "Indices", type: :feature do
  SOLR_INSTANCE = SolrWrapper.default_instance({})
  before(:all) { SOLR_INSTANCE.start }
  after(:all) { SOLR_INSTANCE.stop }

  scenario "User visits home page" do
    visit '/'
    expect(page).to have_text("Welcome!")
  end
end
