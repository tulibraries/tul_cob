# frozen_string_literal: true

require "rails_helper"
require "ostruct"

RSpec.describe "catalog/_show_tools.html.erb" do
  let(:document) { double("SolrDocument", citable?: true) }

  before do
    assign(:document, document)
    allow(Flipflop).to receive(:citeproc_citations?).and_return(false)
    view.define_singleton_method(:show_doc_actions?) { true }
    view.define_singleton_method(:build_error_libwizard_url) { |_doc| "/error" }
    view.define_singleton_method(:render_show_doc_actions) do |_doc, &block|
      config = OpenStruct.new(key: :bookmark)
      block.call(config, "bookmark-inner").to_s
    end
  end

  it "does not render the cite button when citeproc is disabled" do
    render partial: "catalog/show_tools"

    expect(rendered).not_to include("citeLink")
  end
end
