# frozen_string_literal: true

require "rails_helper"

RSpec.describe DatabasesSearchBuilder, type: :model do
  it "keeps Solr field substitutions in combined field-specific clauses" do
    builder = described_class.new(DatabasesController.new)
    builder.with(
      controller: "databases",
      action: "index",
      search_field: "advanced",
      clause: {
        "0" => { field: "title", query: "nature", match: "contains" },
        "1" => { field: "subject", query: "psychology", match: "contains", op: "must" }
      }
    )

    solr_params = builder.processed_parameters

    expect(solr_params["q"]).to eq(
      "( {!edismax qf=$title_qf pf=$title_pf}nature AND {!edismax qf=$subject_qf pf=$subject_pf}psychology )"
    )
    expect(solr_params["defType"]).to eq("lucene")
    expect(solr_params["json"]).to be_nil
  end
end
