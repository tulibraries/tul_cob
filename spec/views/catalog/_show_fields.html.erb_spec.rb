# frozen_string_literal: true

require "rails_helper"

RSpec.describe "catalog/_show_fields.html.erb", type: :view do

  include BlacklightHelper
  include CatalogHelper

  before(:each) do
    allow(controller).to receive(:action_name).and_return("show")
    @config = Blacklight::Configuration.new do |config|
      config.add_facet_field "foo", label: "FOO", show: true, component: true
    end
    @config.show.document_presenter_class = ShowPresenter
    @context = Blacklight::Configuration::Context.new(controller)
    @document = SolrDocument.new(id: 1)
    @document[:format] = []
    without_partial_double_verification do
      allow(view).to receive(:document).and_return(@document)
      allow(view).to receive(:blacklight_config).and_return @config
    end
  end

  it "displays a single value" do
    field = "foo"
    field_config = @config.facet_configuration_for_field(field)
    field_presenter = Blacklight::FieldPresenter.new(view, @document, field_config, value: "bar")
    field_presenter.except_operations << Blacklight::Rendering::Join
    render "catalog/show_fields", document: @document, field_name: field, field_presenter: field_presenter
    expect(rendered).to match(/<dd class="blacklight-foo.*">bar<\/dd>/)
  end

  it "displays two values" do
    field = "foo"
    field_config = @config.facet_configuration_for_field(field)
    field_presenter = Blacklight::FieldPresenter.new(view, @document, field_config, value: ["bar", "hat"])
    field_presenter.except_operations << Blacklight::Rendering::Join
    render "catalog/show_fields", document: @document, field_name: field, field_presenter: field_presenter
    expect(rendered).to include("li class=\"list_items\"> bar </li>")
    expect(rendered).to include("li class=\"list_items\"> hat </li>")
  end

  it "does ignores nil values" do
    field = "foo"
    field_config = @config.facet_configuration_for_field(field)
    field_presenter = Blacklight::FieldPresenter.new(view, @document, field_config, value: ["bar", nil])
    field_presenter.except_operations << Blacklight::Rendering::Join
    render "catalog/show_fields", document: @document, field_name: field, field_presenter: field_presenter
    expect(rendered).to match(/<dd class="blacklight-foo.*">bar<\/dd>/)
  end

  it "doesn't create an empty list" do
    field = "foo"
    field_config = @config.facet_configuration_for_field(field)
    field_presenter = Blacklight::FieldPresenter.new(view, @document, field_config, value: [nil, nil])
    field_presenter.except_operations << Blacklight::Rendering::Join
    render "catalog/show_fields", document: @document, field_name: field, field_presenter: field_presenter
    expect(rendered).not_to match(/<ul>/)
  end
end
