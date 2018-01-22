# frozen_string_literal: true

require "rails_helper"

RSpec.describe "catalog/_show_default.html.erb", type: :view do

  include BlacklightHelper
  include CatalogHelper

  before(:each) do
    allow(controller).to receive(:action_name).and_return("show")
    @config = Blacklight::Configuration.new {}
    @context = Blacklight::Configuration::Context.new(controller)
    @document = SolrDocument.new(id: 1)
    @document[:format] = []
    without_partial_double_verification do
      allow(view).to receive(:blacklight_config).and_return(@config)
      allow(view).to receive(:blacklight_config).and_return(@config)
      allow(view).to receive(:blacklight_configuration_context).and_return(@context)
      allow(view).to receive(:staff_view_path).and_return("/catalog/1/staff_view")
    end
    stub_template "catalog/_show_availability_section.html.erb" => ""
    stub_template "catalog/_aeon_request.html.erb" => ""
    @rendered = view.render_document_partial @document, :show
  end

  it "Creates the expected tStaff View link" do
    expect(@rendered).to match(/Staff View/)
  end

end
