# frozen_string_literal: true

require "rails_helper"

RSpec.describe CatalogSearchSidebarComponent, type: :component do
  let(:view_config) { blacklight_config.view_config(:index) }
  let(:response) { instance_double("Blacklight::Solr::Response") }
  let(:blacklight_config) {
    config = Blacklight::Configuration.new
    allow(config).to receive(:facet_group_names).and_return([])
    allow(config).to receive(:facet_fields_in_group).and_return([])
    config
  }
  let(:params) { ActionController::Parameters.new(qf: "buzz") }

  before do
    allow(Flipflop).to receive(:solr_query_tweaks?).and_return(true)
  end

  it "renders the tweak query component in the sidebar" do
    rendered = render_inline(described_class.new(blacklight_config:, response:, view_config:, params:))
    expect(rendered.to_html).to include("Tweak Solr Query Fields")
  end
end
