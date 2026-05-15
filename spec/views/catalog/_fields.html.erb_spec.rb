# frozen_string_literal: true

require "rails_helper"

RSpec.describe "catalog/_fields.html.erb", type: :view do
  let(:document) { SolrDocument.new(id: "test-1") }
  let(:field_config) do
    Blacklight::OpenStructWithHashAccess.new(raw: true, type: nil, no_label: true)
  end
  let(:field_presenter) { instance_double(Blacklight::FieldPresenter) }
  let(:presenter) { instance_double(IndexPresenter) }

  before do
    allow(view).to receive(:document_presenter).with(document).and_return(presenter)
    allow(view).to receive(:render_alma_availability).with(document).and_return("")
    allow(presenter).to receive(:fields_to_render).and_yield(
      "format", field_config, field_presenter
    )
    allow(presenter).to receive(:field_value).with(field_config).and_return(
      ["<span class='journal_periodical'> Journal/Periodical</span>"]
    )
    allow(presenter).to receive(:lc_call_number_field_to_render)
  end

  it "does not render raw field values as Ruby array strings" do
    render partial: "catalog/fields", locals: { document: document }

    expect(rendered).to include("<span class='journal_periodical'> Journal/Periodical</span>")
    expect(rendered).not_to include("[\"")
  end
end
