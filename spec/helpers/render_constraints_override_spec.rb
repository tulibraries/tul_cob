# frozen_string_literal: true

require "rails_helper"

RSpec.describe BlacklightAdvancedSearch::RenderConstraintsOverride do

  let(:config) do
    Blacklight::Configuration.new do |config|
      config.add_facet_field 'type'
    end
  end

  before do
    # the helper methods below infer paths from the current route
    controller.request.path_parameters[:controller] = 'catalog'
    allow_any_instance_of(BlacklightAdvancedSearch::RenderConstraintsOverride).to receive(:guided_search).and_return([["All Fields", " cetecean", ["search_field", "q", nil]]])
    allow_any_instance_of(BlacklightAdvancedSearch::CatalogHelperOverride).to receive(:remove_guided_keyword_query).and_return({"utf8"=>"✓", "controller"=>"primo_central", "action"=>"index"})
  end

  context "Catalog search" do
    #let catalog_params {{"utf8"=>"✓", "search_field"=>"all_fields", "q"=>"cetecean", "controller"=>"catalog", "action"=>"index"}}
    let(:catalog_params) { ActionController::Parameters.new "utf8"=>"✓", "search_field"=>"all_fields", "q"=>"cetecean", "controller"=>"catalog", "action"=>"index" }

    it "simple catalog search" do
      binding.pry
      val = render_constraints_query(catalog_params)
      expect(helper.op_row_default(2)).to eq("bar")
    end
  end

  context "Article search" do
  end
end
