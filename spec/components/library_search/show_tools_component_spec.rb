# frozen_string_literal: true

require "rails_helper"
require "ostruct"

RSpec.describe LibrarySearch::ShowToolsComponent, type: :component do
  class FakeShowToolActionComponent < ViewComponent::Base
    def initialize(**)
    end

    def call
      "<a class=\"nav-link\" id=\"bookmarkLink\">Bookmark</a>".html_safe
    end
  end

  let(:document) { instance_double("SolrDocument", citable?: true) }
  let(:bookmark_action) { OpenStruct.new(key: :bookmark, component: FakeShowToolActionComponent) }
  let(:component) { described_class.new(document:) }

  before do
    allow(Flipflop).to receive(:citeproc_citations?).and_return(false)
    allow(component).to receive(:actions).and_return([bookmark_action])
    allow(component).to receive(:error_link).and_return("<a id=\"errorLink\" class=\"btn\">Report a Problem</a>".html_safe)
  end

  it "does not render the cite button when citeproc is disabled" do
    rendered = render_inline(component)

    expect(rendered.css("#bookmarkLink")).not_to be_empty
    expect(rendered.css("#errorLink")).not_to be_empty
    expect(rendered.to_html).not_to include("citeLink")
  end
end
